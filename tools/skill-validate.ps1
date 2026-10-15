# SYNOPSIS: Validate skill folders (SKILL.md frontmatter, name matches folder, description length, diagram)
# USAGE: bt skill-validate [-Path <skills dir>]
param([string]$Path = '')
$ErrorActionPreference = 'SilentlyContinue'
if (-not $Path) { $Path = Join-Path (Split-Path -Parent $PSScriptRoot) 'skills' }
$errs = 0; $n = 0
foreach ($d in (Get-ChildItem -LiteralPath $Path -Directory)) {
  $n++
  $f = Join-Path $d.FullName 'SKILL.md'
  if (-not (Test-Path -LiteralPath $f)) { Write-Output ($d.Name + ': missing SKILL.md'); $errs++; continue }
  $txt = (Get-Content -LiteralPath $f -Raw) -replace "`r`n", "`n"
  if (-not ($txt -match '(?s)^---\n(.*?)\n---\n')) { Write-Output ($d.Name + ': bad frontmatter'); $errs++; continue }
  $fm = $Matches[1]
  $name = ''; $desc = ''
  if ($fm -match '(?m)^name:\s*(.+)$') { $name = $Matches[1].Trim() }
  if ($fm -match '(?m)^description:\s*(.+)$') { $desc = $Matches[1].Trim() }
  if ($name -ne $d.Name) { Write-Output ($d.Name + ": name mismatch ('$name')"); $errs++ }
  if ($desc.Length -lt 40 -or $desc.Length -gt 1024) { Write-Output ($d.Name + ': description length ' + $desc.Length); $errs++ }
  if (-not (Test-Path -LiteralPath (Join-Path $d.FullName 'diagram.mmd'))) { Write-Output ($d.Name + ': missing diagram.mmd'); $errs++ }
}
Write-Output "$n skills checked, $errs problem(s)"
if ($errs -gt 0) { exit 1 }
Write-Output 'OK'
