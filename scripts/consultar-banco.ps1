[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$ContainerGroup,
    [ValidateRange(0,[long]::MaxValue)][long]$FarmId=0,
    [ValidateRange(0,[long]::MaxValue)][long]$CropAreaId=0,
    [ValidateRange(0,[long]::MaxValue)][long]$SensorId=0,
    [ValidateRange(0,[long]::MaxValue)][long]$ActivityId=0
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
az container exec -g $ResourceGroup -n $ContainerGroup --container-name postgres --exec-command "/usr/local/bin/agro-evidence $FarmId $CropAreaId $SensorId $ActivityId"
