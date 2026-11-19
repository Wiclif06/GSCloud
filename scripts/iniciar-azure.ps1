#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Infraestrutura','DevOps','Politicas','Pipelines')][string]$Etapa,
    [string]$ConfigFile=(Join-Path $PSScriptRoot '../config/implantacao.local.json'),
    [switch]$EnableAi,
    [switch]$ResumeProvisioning
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'Instale o Azure CLI antes de executar a etapa Azure.' }
if (-not (Test-Path -LiteralPath $ConfigFile)) { throw 'Copie config/implantacao.example.json para config/implantacao.local.json e informe os dados reais, sem senhas.' }
$c=Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$allowed=@('subscriptionId','prefix','location','organization','project','reviewerEmail','professorEmail')
foreach ($property in $c.PSObject.Properties.Name) { if ($property -notin $allowed) { throw "Campo inesperado: $property. Não armazene senhas/chaves no JSON." } }
function Required([string]$Name) {
    if ([string]::IsNullOrWhiteSpace([string]$c.$Name)) { throw "Preencha $Name no arquivo de configuração." }
}
if ($Etapa -eq 'Infraestrutura') {
    Required 'subscriptionId';Required 'prefix';Required 'location'
    [void][guid]::Parse($c.subscriptionId)
    $saved=@{}
    $secretNames=@('POSTGRES_PASSWORD','RABBITMQ_PASSWORD','JWT_SECRET')
    if ($EnableAi) { $secretNames+='GOOGLE_API_KEY' }
    try {
        foreach ($name in $secretNames) {
            $saved[$name]=[Environment]::GetEnvironmentVariable($name)
            if (-not $saved[$name]) { [Environment]::SetEnvironmentVariable($name,(Read-Host "$name (não será gravado em arquivo)" -MaskInput)) }
        }
        & (Join-Path $PSScriptRoot 'provisionar-azure.ps1') -SubscriptionId $c.subscriptionId -Prefix $c.prefix -Location $c.location -EnableAi:$EnableAi -ResumeProvisioning:$ResumeProvisioning
    } finally { foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name]) } }
} elseif ($Etapa -eq 'DevOps') {
    foreach ($name in @('organization','project','reviewerEmail','professorEmail')) { Required $name }
    & (Join-Path $PSScriptRoot 'configurar-devops.ps1') -Organization $c.organization -Project $c.project -ReviewerEmail $c.reviewerEmail -ProfessorEmail $c.professorEmail
} else {
    foreach ($name in @('organization','project','reviewerEmail')) { Required $name }
    $outputFile=Join-Path $PSScriptRoot '../devops-output.json'
    if (-not (Test-Path -LiteralPath $outputFile)) { throw 'Execute primeiro a etapa DevOps para obter o ID real do repositório.' }
    $d=Get-Content -LiteralPath $outputFile -Raw | ConvertFrom-Json
    if ($d.ORGANIZATION.TrimEnd('/') -ne $c.organization.TrimEnd('/') -or $d.PROJECT -ne $c.project) { throw 'A organização/projeto da configuração diverge do repositório cadastrado.' }
    if ($Etapa -eq 'Politicas') {
        & (Join-Path $PSScriptRoot 'proteger-main.ps1') -Organization $c.organization -Project $c.project -RepositoryId $d.REPOSITORY_ID -ReviewerEmail $c.reviewerEmail
    } else {
        & (Join-Path $PSScriptRoot 'criar-pipelines.ps1') -Organization $c.organization -Project $c.project -RepositoryId $d.REPOSITORY_ID
    }
}
