# SYNOPSIS: List all Model-Booster tools or show help for one
# USAGE: bt [list]   |   bt help <tool>
param([string]$Help = '')
$dir = $PSScriptRoot
if ($Help) {
  $f = Join-Path $dir ($Help + '.ps1')
  if (-not (Test-Path -LiteralPath $f)) { Write-Output "unknown tool: $Help (run: bt list)"; exit 2 }
  Get-Content -LiteralPath $f -TotalCount 4 | Where-Object { $_ -match '^#' } | ForEach-Object { Write-Output ($_ -replace '^#\s?', '') }
  exit 0
}
Write-Output 'Model-Booster tools  (run: bt <tool> <args>   |   bt help <tool>)'
Get-ChildItem -LiteralPath $dir -Filter *.ps1 | Where-Object { $_.Name -notin 'bt.ps1', 'install.ps1' } | Sort-Object Name | ForEach-Object {
  $syn = ''
  $line = Get-Content -LiteralPath $_.FullName -TotalCount 2 | Where-Object { $_ -match '^#\s*SYNOPSIS:' } | Select-Object -First 1
  if ($line) { $syn = ($line -replace '^#\s*SYNOPSIS:\s*', '') }
  Write-Output ('  {0,-16} {1}' -f $_.BaseName, $syn)
}
