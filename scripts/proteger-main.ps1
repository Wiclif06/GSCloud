#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Organization,
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$RepositoryId,
    [Parameter(Mandatory)][string]$ReviewerEmail
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
$policies=@(az repos policy list --org $Organization --project $Project --repository-id $RepositoryId --branch main -o json | ConvertFrom-Json)
$common=@('--org',$Organization,'--project',$Project,'--repository-id',$RepositoryId,'--branch','main','--enabled','true','--blocking','true')
function Set-Policy([string]$Kind,[string]$TypeId,[string[]]$Options) {
    $matchingPolicies=@($policies | Where-Object {$_.type.id -eq $TypeId})
    if ($matchingPolicies.Count) {
        foreach ($policy in $matchingPolicies) { az repos policy $Kind update --id $policy.id @common @Options --output none }
    } else { az repos policy $Kind create @common @Options --output none }
}
Set-Policy 'approver-count' 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd' @('--minimum-approver-count','1','--creator-vote-counts','true','--allow-downvotes','false','--reset-on-source-push','true')
Set-Policy 'work-item-linking' '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e' @()
Set-Policy 'required-reviewer' 'fd2167ab-b0be-447a-8ec8-39368250530e' @('--required-reviewer-ids',$ReviewerEmail,'--message','Revisão obrigatória RM563901')
# Configura a autoaprovação dos revisores incluídos pela API de políticas.
$current=@(az repos policy list --org $Organization --project $Project --repository-id $RepositoryId --branch main -o json | ConvertFrom-Json)
foreach ($policy in @($current | Where-Object {$_.type.id -in @('fd2167ab-b0be-447a-8ec8-39368250530e','fa4e907d-c16b-4a4c-9dfa-4906e5d171dd')})) {
    $policy.settings | Add-Member -NotePropertyName creatorVoteCounts -NotePropertyValue $true -Force
    if ($policy.type.id -eq 'fa4e907d-c16b-4a4c-9dfa-4906e5d171dd') {
        $policy.settings | Add-Member -NotePropertyName blockLastPusherVote -NotePropertyValue $false -Force
    }
    $config=@{isEnabled=$true;isBlocking=$true;type=@{id=$policy.type.id};settings=$policy.settings}
    $temp=Join-Path ([IO.Path]::GetTempPath()) ('agro-policy-'+[guid]::NewGuid()+'.json')
    try {
        $config | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $temp -Encoding utf8
        az repos policy update --id $policy.id --config $temp --org $Organization --project $Project --output none
    } finally { Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue }
}
az repos update --repository $RepositoryId --default-branch refs/heads/main --org $Organization --project $Project --output none
$verified=@(az repos policy list --org $Organization --project $Project --repository-id $RepositoryId --branch main -o json | ConvertFrom-Json)
foreach ($id in @('fa4e907d-c16b-4a4c-9dfa-4906e5d171dd','40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e','fd2167ab-b0be-447a-8ec8-39368250530e')) {
    if (-not @($verified | Where-Object {$_.type.id -eq $id -and $_.isEnabled -and $_.isBlocking}).Count) { throw 'Uma das três políticas obrigatórias não foi confirmada.' }
}
foreach ($policy in @($verified | Where-Object {$_.type.id -in @('fd2167ab-b0be-447a-8ec8-39368250530e','fa4e907d-c16b-4a4c-9dfa-4906e5d171dd')})) {
    if (-not $policy.settings.creatorVoteCounts) { throw 'Autoaprovação de simulação não foi confirmada em uma das políticas.' }
}
Write-Host 'Três políticas obrigatórias confirmadas. Confira também que a equipe não possui bypass ao fazer push/concluir PR.'

