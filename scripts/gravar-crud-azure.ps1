#requires -Version 7.4
[CmdletBinding()]
param(
    [string]$BaseUrl='https://app-agro563901gs.azurewebsites.net',
    [string]$ResourceGroup='rg-agro563901gs',
    [string]$ContainerGroup='aci-agro563901gs',
    [string]$SubscriptionId='eecf8d38-81e0-46a2-b0b8-d4db69e172ce'
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI não encontrado. Abra um terminal com Azure CLI instalado e autenticado.'
}
$current=(az account show --query id -o tsv --only-show-errors).Trim()
if ($LASTEXITCODE -ne 0 -or $current -ne $SubscriptionId) {
    throw 'Autentique o Azure CLI e selecione a assinatura correta da equipe antes do CRUD.'
}
if ((Invoke-RestMethod "$($BaseUrl.TrimEnd('/'))/actuator/health" -TimeoutSec 20).status -ne 'UP') {
    throw 'A aplicação não está saudável. Resolva o health antes da gravação.'
}
Write-Host "Aplicação: $BaseUrl"
Write-Host "Banco em nuvem: $ResourceGroup / $ContainerGroup / postgres"
& (Join-Path $PSScriptRoot 'smoke-test.ps1') -BaseUrl $BaseUrl -PauseForSql -ResourceGroup $ResourceGroup -ContainerGroup $ContainerGroup
