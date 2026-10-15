# SYNOPSIS: Update a step or acceptance item in .agent\PLAN.md (status + evidence) and the status block
# USAGE: bt plan-update -Id S1 -Status doing|done|failed|blocked|todo [-Evidence "dotnet test: passed"]
param(
  [Parameter(Mandatory = $true)][string]$Id,
  [Parameter(Mandatory = $true)][ValidateSet('todo', 'doing', 'done', 'failed', 'blocked')][string]$Status,
  [string]$Evidence = '',
  [string]$Path = '.'
)
$ErrorActionPreference = 'Stop'
$file = Join-Path (Join-Path (Resolve-Path -LiteralPath $Path).Path '.agent') 'PLAN.md'
if (-not (Test-Path -LiteralPath $file)) { Write-Output 'PLAN.md missing: run "bt agent-init" first'; exit 2 }
$lines = @(Get-Content -LiteralPath $file)
$idRe = [regex]::Escape($Id)
$found = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match ('^(\s*)- \[[ xX]\] ' + $idRe + '(\s|$)')) {
    $found = $true
    $l = $lines[$i] -replace '\s*\|\s*(todo|doing|done|failed|blocked):.*$', ''
    if ($Status -eq 'done') { $l = $l -replace '- \[[ xX]\]', '- [x]' } else { $l = $l -replace '- \[[ xX]\]', '- [ ]' }
    $l = $l + ' | ' + $Status + ': ' + $Evidence
    $lines[$i] = $l.TrimEnd()
  }
}
if (-not $found) { Write-Output "item $Id not found in PLAN.md"; exit 3 }
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($Status -eq 'doing' -and $lines[$i] -match '^IN PROGRESS:') { $lines[$i] = "IN PROGRESS: $Id" }
  if ($Status -eq 'blocked' -and $lines[$i] -match '^BLOCKED:') { $lines[$i] = "BLOCKED: $Id $Evidence" }
  if ($Status -eq 'done' -and $lines[$i] -match '^LAST VERIFIED:' -and $Evidence) { $lines[$i] = "LAST VERIFIED: $Evidence" }
  if ($Status -eq 'done' -and $lines[$i] -match ('^IN PROGRESS:\s*' + $idRe + '\s*$')) { $lines[$i] = 'IN PROGRESS:' }
}
Set-Content -LiteralPath $file -Value $lines -Encoding UTF8
Write-Output "updated $Id -> $Status"
