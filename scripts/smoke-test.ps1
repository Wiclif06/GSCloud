[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseUrl,
    [switch]$PauseForSql,
    [string]$ResourceGroup,
    [string]$ContainerGroup,
    [scriptblock]$VerifySql
)
$ErrorActionPreference='Stop'
$url=$BaseUrl.TrimEnd('/')
$headers=@{}
$suffix=[guid]::NewGuid().ToString('N').Substring(0,10)
$password='Gs!'+[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(20))
$email="gs-$suffix@example.invalid"
$farmId=0; $cropId=0; $sensorId=0; $activityId=0
function CallApi([string]$Path,[string]$Method,[int]$Expected,$Body=$null) {
    $params=@{Uri="$url/api/$Path";Method=$Method;Headers=$headers;StatusCodeVariable='httpStatus'}
    if ($null -ne $Body) { $params['ContentType']='application/json'; $params['Body']=$Body | ConvertTo-Json -Depth 10 }
    $result=Invoke-RestMethod @params
    if ($httpStatus -ne $Expected) { throw "$Method $Path retornou $httpStatus; esperado $Expected." }
    return $result
}
function Evidence([string]$Step) {
    Write-Host "`n$Step | Farm=$farmId | CropArea=$cropId | Sensor=$sensorId | Activity=$activityId"
    if ($VerifySql) { & $VerifySql $Step $farmId $cropId $sensorId $activityId }
    if ($PauseForSql) {
        if ($ResourceGroup -and $ContainerGroup) {
            & (Join-Path $PSScriptRoot 'consultar-banco.ps1') -ResourceGroup $ResourceGroup -ContainerGroup $ContainerGroup -FarmId $farmId -CropAreaId $cropId -SensorId $sensorId -ActivityId $activityId
        } else {
            Write-Host "SELECT id,name,city,total_area FROM farms WHERE id=$farmId;"
            Write-Host "SELECT id,farm_id,name,area_size FROM crop_areas WHERE id=$cropId;"
            Write-Host "SELECT id,name,status FROM sensors WHERE id=$sensorId;"
            Write-Host "SELECT id,type,description FROM field_activities WHERE id=$activityId;"
        }
        Read-Host 'Mostre o SELECT diretamente no PostgreSQL em nuvem; explique o resultado e pressione Enter' | Out-Null
    }
}
function AssertGone([string]$Path) {
    $code=0
    try { Invoke-RestMethod "$url/api/$Path" -Headers $headers | Out-Null }
    catch { $code=[int]$_.Exception.Response.StatusCode }
    if ($code -ne 404) { throw "Recurso excluído não retornou 404: $Path" }
}
try {
    # Credenciais e JWT permanecem na memória; não são impressos.
    CallApi 'auth/register' 'Post' 201 @{name="Produtor GS $suffix";email=$email;password=$password} | Out-Null
    $login=CallApi 'auth/login' 'Post' 200 @{email=$email;password=$password}
    if (-not $login.token) { throw 'Login sem token JWT.' }
    $headers=@{Authorization="Bearer $($login.token)"}
    $farm=@{name="Fazenda GS $suffix";city='Campinas';state='SP';totalArea=100;areaUnit='HECTARE'}
    $created=CallApi 'farms' 'Post' 201 $farm; $farmId=$created.id
    if (-not $farmId) { throw 'Farm sem ID.' }
    Evidence 'CREATE farms - 201'
    $read=CallApi "farms/$farmId" 'Get' 200
    if ($read.name -ne $farm.name) { throw 'Leitura de farm divergente.' }
    Evidence 'READ farms - 200'
    $farm.name="Fazenda Atualizada $suffix"
    $updated=CallApi "farms/$farmId" 'Put' 200 $farm
    if ($updated.name -ne $farm.name) { throw 'Atualização de farm divergente.' }
    Evidence 'UPDATE farms - 200'
    $crop=@{farmId=$farmId;name="Talhão GS $suffix";cropType='Milho';areaSize=10;areaUnit='HECTARE';latitude=-22.900000;longitude=-47.060000;description='Área de demonstração da Global Solution.'}
    $created=CallApi 'crop-areas' 'Post' 201 $crop; $cropId=$created.id
    if (-not $cropId) { throw 'CropArea sem ID.' }
    Evidence 'CREATE crop_areas - 201'
    $read=CallApi "crop-areas/$cropId" 'Get' 200
    if ($read.farmId -ne $farmId) { throw 'Relacionamento de crop area divergente.' }
    Evidence 'READ crop_areas - 200'
    $crop.name="Talhão Atualizado $suffix"; $crop.areaSize=12
    $updated=CallApi "crop-areas/$cropId" 'Put' 200 $crop
    if ($updated.name -ne $crop.name) { throw 'Atualização de crop area divergente.' }
    Evidence 'UPDATE crop_areas - 200'
    $sensor=@{cropAreaId=$cropId;name="Sensor GS $suffix";deviceCode="GS-$suffix";sensorType='SOIL_MOISTURE';installationDate=([datetime]::UtcNow.AddDays(-1).ToString('yyyy-MM-dd'));description='Sensor de demonstração sem leituras.'}
    $created=CallApi 'sensors' 'Post' 201 $sensor; $sensorId=$created.id
    if (-not $sensorId) { throw 'Sensor sem ID.' }
    Evidence 'CREATE sensors - 201'
    $read=CallApi "sensors/$sensorId" 'Get' 200
    if ($read.cropAreaId -ne $cropId) { throw 'Relacionamento de sensor divergente.' }
    Evidence 'READ sensors - 200'
    $sensor['status']='INACTIVE'; $sensor.name="Sensor Atualizado $suffix"
    $updated=CallApi "sensors/$sensorId" 'Put' 200 $sensor
    if ($updated.status -ne 'INACTIVE') { throw 'Atualização de sensor divergente.' }
    Evidence 'UPDATE sensors - 200'
    $activity=@{type='IRRIGATION';performedAt=[datetime]::UtcNow.AddMinutes(-2).ToString('o');description="Irrigação GS $suffix";quantity=20;unit='litros'}
    $activityPath="crop-areas/$cropId/activities"
    $created=CallApi $activityPath 'Post' 201 $activity; $activityId=$created.id
    if (-not $activityId) { throw 'Activity sem ID.' }
    Evidence 'CREATE field_activities - 201'
    CallApi "$activityPath/$activityId" 'Get' 200 | Out-Null
    Evidence 'READ field_activities - 200'
    $activity.description="Irrigação revisada $suffix"; $activity.quantity=25
    $updated=CallApi "$activityPath/$activityId" 'Put' 200 $activity
    if ($updated.quantity -ne 25) { throw 'Atualização de activity divergente.' }
    Evidence 'UPDATE field_activities - 200'
    CallApi "$activityPath/$activityId" 'Delete' 204 | Out-Null
    AssertGone "$activityPath/$activityId"
    Evidence 'DELETE field_activities - 204; SELECT deve ficar vazio'
    CallApi "sensors/$sensorId" 'Delete' 204 | Out-Null
    AssertGone "sensors/$sensorId"
    Evidence 'DELETE sensors - 204; SELECT deve ficar vazio'
    CallApi "crop-areas/$cropId" 'Delete' 204 | Out-Null
    AssertGone "crop-areas/$cropId"
    Evidence 'DELETE crop_areas - 204; SELECT deve ficar vazio'
    CallApi "farms/$farmId" 'Delete' 204 | Out-Null
    AssertGone "farms/$farmId"
    Evidence 'DELETE farms - 204; SELECT deve ficar vazio'
    Write-Host 'CRUD concluído nas quatro entidades. O usuário sintético permanece registrado sem fazendas vinculadas.'
} finally {
    # Tenta limpar somente os registros criados nesta execução, na ordem das FKs.
    foreach ($path in @("crop-areas/$cropId/activities/$activityId","sensors/$sensorId","crop-areas/$cropId","farms/$farmId")) {
        if ($path -match '/0($|/)') { continue }
        try { Invoke-RestMethod "$url/api/$path" -Method Delete -Headers $headers | Out-Null } catch { }
    }
}
