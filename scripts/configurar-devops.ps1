#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^https://dev\.azure\.com/[a-zA-Z0-9_-]+/?$')][string]$Organization,
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9 _-]{2,63}$')][string]$Project='AgroConecta-GS-2026',
    [Parameter(Mandatory)][string]$ReviewerEmail,
    [Parameter(Mandatory)][string]$ProfessorEmail
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$true
foreach ($email in @($ReviewerEmail,$ProfessorEmail)) { [void][System.Net.Mail.MailAddress]::new($email) }
az extension add --name azure-devops --only-show-errors
az devops configure --defaults organization=$Organization project=$Project
$projects=az devops project list --org $Organization -o json | ConvertFrom-Json
$p=@($projects.value | Where-Object name -eq $Project) | Select-Object -First 1
if (-not $p) {
    $p=az devops project create --name $Project --org $Organization --visibility private --source-control git --process Agile -o json | ConvertFrom-Json
} elseif ($p.visibility -ne 'private') { throw 'O projeto existente não é privado. Selecione um projeto privado próprio da GS.' }
$repos=@(az repos list --org $Organization --project $Project -o json | ConvertFrom-Json)
$repo=$repos | Where-Object name -eq $Project | Select-Object -First 1
if (-not $repo) { $repo=az repos create --name $Project --org $Organization --project $Project -o json | ConvertFrom-Json }
$users=az devops user list --org $Organization --top 10000 -o json | ConvertFrom-Json
$professor=@($users.members | Where-Object {$_.user.principalName -eq $ProfessorEmail -or $_.user.mailAddress -eq $ProfessorEmail}) | Select-Object -First 1
if ($professor) {
    az devops user update --user $ProfessorEmail --license-type express --org $Organization --output none
} else {
    az devops user add --email-id $ProfessorEmail --license-type express --org $Organization --send-email-invite true --output none
}
$professor=az devops user show --user $ProfessorEmail --org $Organization -o json | ConvertFrom-Json
if ($professor.accessLevel.accountLicenseType -ne 'express') { throw 'Não foi possível confirmar licença Basic do professor.' }
$groups=az devops security group list --org $Organization --project $Project -o json | ConvertFrom-Json
$admins=$groups.graphGroups | Where-Object {$_.principalName -like '*\Project Administrators'} | Select-Object -First 1
if (-not $admins) { throw 'Project Administrators não encontrado. Confira o grupo de administradores na interface.' }
az devops security group membership add --org $Organization --group-id $admins.descriptor --member-id $professor.user.descriptor --output none
$title='Publicar AgroConecta com rastreabilidade de ponta a ponta'
$wiql="SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject]='$Project' AND [System.WorkItemType]='Task' AND [System.Title]='$title'"
$items=@(az boards query --org $Organization --project $Project --wiql $wiql -o json | ConvertFrom-Json)
$task=$items | Select-Object -First 1
if (-not $task) {
    $task=az boards work-item create --org $Organization --project $Project --type Task --title $title --description 'Critérios: branch por tarefa, commit AB#ID, PR revisada, CI com testes e artefato, Release automática e CRUD/SELECT em PostgreSQL no ACI.' -o json | ConvertFrom-Json
}
$result=[ordered]@{ORGANIZATION=$Organization;PROJECT=$Project;PROJECT_ID=$p.id;REPOSITORY_ID=$repo.id;REPOSITORY_URL=$repo.remoteUrl;INITIAL_TASK_ID=$task.id;REVIEWER_EMAIL=$ReviewerEmail}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot '../devops-output.json') -Encoding utf8
Write-Host "Tarefa inicial: $($task.id) | Repositório: $($repo.remoteUrl)"
Write-Host 'Bootstrap, antes de proteger main: git init -b main; git add .'
Write-Host "git commit -m `"feat: AgroConecta Cloud AB#$($task.id)`""
Write-Host "git remote add origin $($repo.remoteUrl)"
Write-Host 'git push -u origin main'
Write-Host "./scripts/proteger-main.ps1 -Organization '$Organization' -Project '$Project' -RepositoryId '$($repo.id)' -ReviewerEmail '$ReviewerEmail'"
Write-Host 'Confira o aceite do convite e a associação do professor em Project Administrators na interface.'
