#requires -Version 7.4
[CmdletBinding()]
param(
    [switch]$SkipMaven,
    [ValidatePattern('^agrotest-[a-z0-9-]{4,35}$')][string]$ProjectName=('agrotest-'+[guid]::NewGuid().ToString('N').Substring(0,10))
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$compose=Join-Path $root 'compose.cloud-test.yml'
$dc=@('compose','--project-name',$ProjectName,'--file',$compose)
$started=$false
$stage='pre-requisitos'
$tests=[Collections.Generic.List[object]]::new()
$reportDir=Join-Path $root 'target/cloud-reports'
$migrationCount=@(Get-ChildItem (Join-Path $root 'src/main/resources/db/migration') -Filter 'V*.sql').Count
$saved=@{}
foreach ($name in @('AGRO_TEST_DB_PASSWORD','AGRO_TEST_RABBIT_PASSWORD','AGRO_TEST_JWT_SECRET')) {
    $saved[$name]=[Environment]::GetEnvironmentVariable($name)
    [Environment]::SetEnvironmentVariable($name,[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)))
}
function Sql([string]$Query) {
    $r=@(docker @dc exec -T postgres psql -h 127.0.0.1 -U agroconecta -d citizentech -v ON_ERROR_STOP=1 -At -c $Query)
    if ($LASTEXITCODE -ne 0) { throw 'Consulta SQL de validação falhou.' }
    return ($r -join "`n").Trim()
}
function WaitApi([string]$Url) {
    for ($i=0;$i -lt 60;$i++) {
        try { if ((Invoke-RestMethod "$Url/actuator/health" -TimeoutSec 5).status -eq 'UP') { return } } catch { }
        Start-Sleep -Seconds 3
    }
    throw 'Health da aplicação de teste não ficou UP.'
}
try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker é necessário para validar integração e restauração. Instale/inicie Docker antes de executar este script.' }
    if ((docker info --format '{{.OSType}}') -ne 'linux') { throw 'Selecione o engine de containers Linux no Docker.' }
    docker compose version --short | Out-Host
    $existing=@(docker @dc ps --all --quiet)
    if ($existing.Count -gt 0) { throw 'O nome de projeto já possui containers. Use outro ProjectName; o teste não remove ambientes existentes.' }
    Push-Location $root
    try {
        if (-not $SkipMaven) {
            $stage='maven-integracao'
            $wrapper=if ($IsWindows) { './mvnw.cmd' } else { './mvnw' }
            if (-not $IsWindows) { chmod +x ./mvnw }
            & $wrapper -B -ntp clean verify
            if ($LASTEXITCODE -ne 0) { throw 'Maven clean verify falhou.' }
        }
    } finally { Pop-Location }
    $jar=Join-Path $root 'target/citizentech-api-0.0.1-SNAPSHOT.jar'
    if (-not (Test-Path -LiteralPath $jar)) { throw 'JAR não encontrado. Execute Maven antes de usar -SkipMaven.' }
    $stage='startup-producao-e-flyway'
    $started=$true
    docker @dc up --build -d
    $address=(docker @dc port api 8080).Trim()
    $url="http://$address"
    WaitApi $url
    if ((Sql 'SELECT count(*) FROM flyway_schema_history WHERE success;') -ne [string]$migrationCount) { throw 'As migrações versionadas não foram aplicadas.' }
    $tests.Add(@{name=$stage;success=$true})
    $stage='crud-quatro-tabelas-com-select'
    $verify={
        param($Step,[long]$Farm,[long]$Crop,[long]$Sensor,[long]$Activity)
        if ($Step -notmatch '^(CREATE|READ|UPDATE|DELETE) (farms|crop_areas|sensors|field_activities)') { throw 'Etapa de SQL não reconhecida.' }
        $operation=$Matches[1];$table=$Matches[2]
        $id=switch ($table) { farms {$Farm} crop_areas {$Crop} sensors {$Sensor} field_activities {$Activity} }
        $expected=if ($operation -eq 'DELETE') {'0'} else {'1'}
        if ((Sql "SELECT count(*) FROM $table WHERE id=$id;") -ne $expected) { throw "Persistência divergente em $table/$operation." }
        if ($operation -eq 'UPDATE') {
            $condition=switch ($table) {
                farms {"name LIKE 'Fazenda Atualizada %'"}
                crop_areas {'area_size=12'}
                sensors {"status='INACTIVE'"}
                field_activities {'quantity=25'}
            }
            if ((Sql "SELECT count(*) FROM $table WHERE id=$id AND $condition;") -ne '1') { throw "UPDATE não persistido em $table." }
        }
        Write-Host "SELECT validado: $table / $operation"
    }
    & (Join-Path $PSScriptRoot 'smoke-test.ps1') -BaseUrl $url -VerifySql $verify
    $tests.Add(@{name=$stage;success=$true})
    $stage='snapshot-e-restauracao-em-pgdata-vazio'
    $marker=[guid]::NewGuid().ToString('N')
    Sql "CREATE TABLE cloud_backup_probe(id integer PRIMARY KEY,marker text NOT NULL); INSERT INTO cloud_backup_probe VALUES(1,'$marker');" | Out-Null
    docker @dc exec -T postgres /usr/local/bin/agro-backup-once
    # Apenas o container descartável de PostgreSQL é recriado. O volume de snapshots permanece.
    docker @dc stop --timeout 90 postgres
    docker @dc rm --force --volumes postgres
    docker @dc up -d postgres
    $restored=$false
    $PSNativeCommandUseErrorActionPreference=$false
    for ($i=0;$i -lt 60;$i++) {
        try {
            if ((Sql 'SELECT marker FROM cloud_backup_probe WHERE id=1;') -eq $marker) { $restored=$true;break }
        } catch { }
        Start-Sleep -Seconds 3
    }
    $PSNativeCommandUseErrorActionPreference=$true
    if (-not $restored) { throw 'Marcador não foi restaurado a partir do snapshot.' }
    if ((Sql 'SELECT count(*) FROM flyway_schema_history WHERE success;') -ne [string]$migrationCount) { throw 'Histórico Flyway não foi restaurado.' }
    WaitApi $url
    $tests.Add(@{name=$stage;success=$true})
    Write-Host 'Validação completa: startup prod, migrações, CRUD/SELECT e restauração de snapshot.'
} catch {
    $tests.Add(@{name=$stage;success=$false;errorType=$_.Exception.GetType().Name})
    throw
} finally {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    $xml=[Xml.XmlDocument]::new()
    $suite=$xml.CreateElement('testsuite');$suite.SetAttribute('name','AgroConecta.Cloud');$suite.SetAttribute('tests',[string]$tests.Count)
    $suite.SetAttribute('failures',[string]@($tests | Where-Object {-not $_.success}).Count);$xml.AppendChild($suite) | Out-Null
    foreach ($test in $tests) {
        $case=$xml.CreateElement('testcase');$case.SetAttribute('name',$test.name);$case.SetAttribute('classname','AgroConecta.Cloud')
        if (-not $test.success) { $failure=$xml.CreateElement('failure');$failure.SetAttribute('message',"Falha na etapa $($test.name): $($test.errorType)");$case.AppendChild($failure) | Out-Null }
        $suite.AppendChild($case) | Out-Null
    }
    $xml.Save((Join-Path $reportDir 'TEST-cloud-readiness.xml'))
    try {
        if ($started) { docker @dc down --volumes --remove-orphans | Out-Host }
    } finally {
        foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name]) }
    }
}
