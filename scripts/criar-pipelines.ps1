#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Organization,[string]$Project='AgroConecta-GS-2026',[Parameter(Mandatory)][string]$RepositoryId)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
$existing=@(az pipelines list --org $Organization --project $Project -o json | ConvertFrom-Json)
foreach ($entry in @(@{name='AgroConecta-CI';file='azure-pipeline.yml'},@{name='AgroConecta-Release';file='azure-release.yml'})) {
    $p=$existing | Where-Object name -eq $entry.name | Select-Object -First 1
    if ($p) {
        az pipelines update --id $p.id --org $Organization --project $Project --branch main --yml-path $entry.file --output none
    } else {
        az pipelines create --org $Organization --project $Project --name $entry.name --repository $RepositoryId --repository-type tfsgit --branch main --yml-path $entry.file --skip-first-run true --output none
    }
}
Write-Host 'Pipelines cadastradas/atualizadas sem execução manual de demonstração. Configure conexão, Library e Environment antes da primeira PR.'
