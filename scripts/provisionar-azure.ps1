#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SubscriptionId,
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{4,16}[a-z0-9]$')][string]$Prefix,
    [string]$Location = 'eastus',
    [switch]$EnableAi,
    [switch]$ResumeProvisioning
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference=$true
if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'Instale Azure CLI antes do provisionamento.' }
foreach ($name in @('POSTGRES_PASSWORD','RABBITMQ_PASSWORD','JWT_SECRET')) {
    $value=[Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value) -or $value.Length -lt 32) { throw "Defina $name com pelo menos 32 caracteres." }
}
if (@($env:POSTGRES_PASSWORD,$env:RABBITMQ_PASSWORD,$env:JWT_SECRET | Select-Object -Unique).Count -ne 3) { throw 'PostgreSQL, RabbitMQ e JWT devem usar segredos diferentes.' }
if ($EnableAi -and -not $env:GOOGLE_API_KEY) { throw 'GOOGLE_API_KEY é obrigatória para -EnableAi.' }
az account set --subscription $SubscriptionId
foreach ($provider in @('Microsoft.Web','Microsoft.ContainerInstance','Microsoft.ContainerRegistry','Microsoft.ManagedIdentity','Microsoft.Storage','Microsoft.Network')) {
    $state=az provider show --namespace $provider --query registrationState -o tsv
    if ($state -ne 'Registered') { az provider register --namespace $provider --wait --output none }
}
$rg="rg-$Prefix"; $vnet="vnet-$Prefix"; $plan="plan-$Prefix"; $app="app-$Prefix"; $aci="aci-$Prefix"
$compact=$Prefix.Replace('-',''); $acr="acr$compact"; $storage="st$compact"; $identity="id-$Prefix"
if ((az group exists -n $rg -o tsv) -eq 'true' -and -not $ResumeProvisioning) { throw "O grupo $rg já existe. Use -ResumeProvisioning somente para retomar o provisionamento com os mesmos segredos. Atualizações de código usam a Release." }
az group create -n $rg -l $Location --tags projeto=AgroConecta representante=rm563901 --output none
az network vnet create -g $rg -n $vnet -l $Location --address-prefixes 10.56.0.0/16 --subnet-name app-service --subnet-prefixes 10.56.1.0/24 --output none
az network vnet subnet update -g $rg --vnet-name $vnet -n app-service --delegations Microsoft.Web/serverFarms --output none
az network vnet subnet create -g $rg --vnet-name $vnet -n containers --address-prefixes 10.56.2.0/24 --delegations Microsoft.ContainerInstance/containerGroups --output none
az network public-ip create -g $rg -n "pip-$Prefix" -l $Location --sku Standard --allocation-method Static --output none
az network nat gateway create -g $rg -n "nat-$Prefix" -l $Location --public-ip-addresses "pip-$Prefix" --idle-timeout 10 --output none
az network vnet subnet update -g $rg --vnet-name $vnet -n containers --nat-gateway "nat-$Prefix" --output none
az storage account create -g $rg -n $storage -l $Location --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --output none
$key=az storage account keys list -g $rg -n $storage --query '[0].value' -o tsv
$oldStorageKey=$env:AZURE_STORAGE_KEY
$env:AZURE_STORAGE_KEY=$key
try { az storage share create --name postgres-backups --account-name $storage --quota 10 --output none }
finally { $env:AZURE_STORAGE_KEY=$oldStorageKey }
az acr create -g $rg -n $acr -l $Location --sku Basic --admin-enabled false --output none
$acrId=az acr show -g $rg -n $acr --query id -o tsv
$login=az acr show -g $rg -n $acr --query loginServer -o tsv
az identity create -g $rg -n $identity -l $Location --output none
$mi=az identity show -g $rg -n $identity -o json | ConvertFrom-Json
$pullRole=az role assignment list --scope $acrId --query "[?principalId=='$($mi.principalId)' && roleDefinitionName=='AcrPull'].id | [0]" -o tsv
if (-not $pullRole) { az role assignment create --assignee-object-id $mi.principalId --assignee-principal-type ServicePrincipal --role AcrPull --scope $acrId --output none }
$projectRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Publish-AcrImage {
    param(
        [Parameter(Mandatory)][string]$Image,
        [Parameter(Mandatory)][string]$Dockerfile
    )
    try {
        az acr build --registry $acr --image $Image --file $Dockerfile $projectRoot --no-logs --output none
        return
    } catch {
        Write-Warning "ACR Tasks indisponível; publicando $Image com Docker local."
    }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker local é necessário quando a assinatura não permite ACR Tasks.'
    }
    az acr login --name $acr --output none
    $remoteImage="$login/$Image"
    docker build --file (Join-Path $projectRoot $Dockerfile) --tag $remoteImage $projectRoot
    docker push $remoteImage
}
Publish-AcrImage -Image 'agro-postgres:gs2026' -Dockerfile 'dockerfiles/postgres.Dockerfile'
Publish-AcrImage -Image 'agro-rabbitmq:gs2026' -Dockerfile 'dockerfiles/rabbitmq.Dockerfile'
$subnet=az network vnet subnet show -g $rg --vnet-name $vnet -n containers --query id -o tsv
$identities=@{}; $identities[$mi.id]=@{}
$spec=@{
    apiVersion='2023-05-01'; name=$aci; location=$Location; type='Microsoft.ContainerInstance/containerGroups'
    identity=@{type='UserAssigned';userAssignedIdentities=$identities}
    properties=@{
        osType='Linux';restartPolicy='Always'
        subnetIds=@(@{id=$subnet})
        ipAddress=@{type='Private';ports=@(@{protocol='TCP';port=5432},@{protocol='TCP';port=5672})}
        imageRegistryCredentials=@(@{server=$login;identity=$mi.id})
        volumes=@(@{name='pg-backup';azureFile=@{shareName='postgres-backups';storageAccountName=$storage;storageAccountKey=$key;readOnly=$false}})
        containers=@(
            @{name='postgres';properties=@{
                image="$login/agro-postgres:gs2026";resources=@{requests=@{cpu=1;memoryInGB=2}}
                ports=@(@{port=5432;protocol='TCP'})
                environmentVariables=@(@{name='POSTGRES_DB';value='citizentech'},@{name='POSTGRES_USER';value='agroconecta'},@{name='POSTGRES_PASSWORD';secureValue=$env:POSTGRES_PASSWORD},@{name='BACKUP_INTERVAL_SECONDS';value='60'})
                volumeMounts=@(@{name='pg-backup';mountPath='/backup'})
            }},
            @{name='rabbitmq';properties=@{
                image="$login/agro-rabbitmq:gs2026";resources=@{requests=@{cpu=1;memoryInGB=1.5}}
                ports=@(@{port=5672;protocol='TCP'})
                environmentVariables=@(@{name='RABBITMQ_DEFAULT_USER';value='agroconecta'},@{name='RABBITMQ_DEFAULT_PASS';secureValue=$env:RABBITMQ_PASSWORD})
            }}
        )
    }
}
$temp=Join-Path ([IO.Path]::GetTempPath()) ("agro-aci-"+[guid]::NewGuid()+'.json')
try {
    $existingAci=az container list -g $rg --query "[?name=='$aci'].name | [0]" -o tsv
    if (-not $existingAci) {
        $spec | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temp -Encoding utf8
        az container create -g $rg --file $temp --output none
    } else { Write-Host 'Container group existente preservado; confira seu estado no Portal Azure.' }
} finally { Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue }
$privateIp=az container show -g $rg -n $aci --query ipAddress.ip -o tsv
if (-not $privateIp) { throw 'Grupo ACI não recebeu IP privado. Confira o estado no Azure.' }
az appservice plan create -g $rg -n $plan -l $Location --is-linux --sku B1 --output none
az webapp create -g $rg -p $plan -n $app --runtime 'JAVA:21-java21' --output none
az webapp update -g $rg -n $app --https-only true --output none
az webapp config set -g $rg -n $app --always-on true --min-tls-version 1.2 --ftps-state Disabled --output none
az webapp vnet-integration add -g $rg -n $app --vnet $vnet --subnet app-service --output none
$settings=@{
    SPRING_PROFILES_ACTIVE='prod'; SPRING_DOCKER_COMPOSE_ENABLED='false'; SERVER_PORT='80'
    DB_URL="jdbc:postgresql://${privateIp}:5432/citizentech"; DB_USERNAME='agroconecta'; DB_PASSWORD=$env:POSTGRES_PASSWORD
    RABBITMQ_HOST=$privateIp;RABBITMQ_PORT='5672';RABBITMQ_USERNAME='agroconecta';RABBITMQ_PASSWORD=$env:RABBITMQ_PASSWORD
    JWT_SECRET=$env:JWT_SECRET; APP_AI_ENABLED=([bool]$EnableAi).ToString().ToLowerInvariant()
    READINGS_MESSAGING_ENABLED='true'; OUTBOX_ENABLED='true'; APP_DEMO_ENABLED='false'
    SCM_DO_BUILD_DURING_DEPLOYMENT='false'
    SPRING_FLYWAY_CONNECT_RETRIES='5'
}
if ($EnableAi) { $settings['GOOGLE_API_KEY']=$env:GOOGLE_API_KEY }
$temp=Join-Path ([IO.Path]::GetTempPath()) ("agro-settings-"+[guid]::NewGuid()+'.json')
try {
    $settings | ConvertTo-Json | Set-Content -LiteralPath $temp -Encoding utf8
    az webapp config appsettings set -g $rg -n $app --settings "@$temp" --output none
} finally { Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue }
$hostName=az webapp show -g $rg -n $app --query defaultHostName -o tsv
$result=[ordered]@{RESOURCE_GROUP=$rg;WEBAPP_NAME=$app;CONTAINER_GROUP=$aci;ACR_NAME=$acr;STORAGE_ACCOUNT=$storage;PRIVATE_IP=$privateIp;APP_URL="https://$hostName";SUBSCRIPTION_ID=$SubscriptionId}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'infra-output.json') -Encoding utf8
$result | ConvertTo-Json
Write-Host 'Infraestrutura criada. Configure o Azure DevOps e publique o JAR pela CI/Release.'
