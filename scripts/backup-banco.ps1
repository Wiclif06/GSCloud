[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResourceGroup,[Parameter(Mandatory)][string]$ContainerGroup)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
az container exec -g $ResourceGroup -n $ContainerGroup --container-name postgres --exec-command '/usr/local/bin/agro-backup-once'
