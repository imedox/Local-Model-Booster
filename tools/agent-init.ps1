# SYNOPSIS: Create .agent\ working files (STATE.md, PLAN.md, MEMORY.md) from templates and keep them out of git
# USAGE: bt agent-init [-Path .]
param([string]$Path = '.')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $Path).Path
$agent = Join-Path $root '.agent'
if (-not (Test-Path -LiteralPath $agent)) { New-Item -ItemType Directory -Path $agent | Out-Null; Write-Output "created $agent" }
$tpl = Join-Path (Split-Path -Parent $PSScriptRoot) 'templates'
foreach ($n in @('STATE.md', 'PLAN.md', 'MEMORY.md')) {
  $dst = Join-Path $agent $n
  if (Test-Path -LiteralPath $dst) { Write-Output "exists  $n (kept)"; continue }
  $src = Join-Path $tpl $n
  if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $dst; Write-Output "created $n" } else { Set-Content -LiteralPath $dst -Value "# $n" -Encoding UTF8; Write-Output "created $n (blank, template missing)" }
}
$gitDir = Join-Path $root '.git'
if (Test-Path -LiteralPath $gitDir -PathType Container) {
  $ex = Join-Path $gitDir 'info\exclude'
  $exDir = Split-Path -Parent $ex
  if (-not (Test-Path -LiteralPath $exDir)) { New-Item -ItemType Directory -Path $exDir | Out-Null }
  $has = $false
  if (Test-Path -LiteralPath $ex) { $has = [bool](Select-String -LiteralPath $ex -Pattern '^\.agent/?$' -Quiet) }
  if (-not $has) { Add-Content -LiteralPath $ex -Value '.agent/'; Write-Output 'added .agent/ to .git/info/exclude' }
}
