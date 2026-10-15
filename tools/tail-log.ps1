# SYNOPSIS: Show the last lines of a log and/or only error/warning lines
# USAGE: bt tail-log -Path build.log [-Lines 100] [-Errors] [-Grep "text"]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [int]$Lines = 100,
  [switch]$Errors,
  [string]$Grep = ''
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Write-Output "File not found: $Path"; exit 2 }
if ($Errors -or $Grep) {
  $re = $Grep
  if (-not $Grep) { $re = '(?i)\b(error|exception|fail(ed|ure)?|fatal|panic|traceback|warning)\b|\bCS\d{4}\b|\bMSB\d{4}\b|\bNU\d{4}\b' }
  $recent = Get-Content -LiteralPath $Path -Tail 3000
  $hits = @($recent | Select-String -Pattern $re)
  Write-Output ("matches in last 3000 lines: " + $hits.Count + ' (showing first 40)')
  $hits | Select-Object -First 40 | ForEach-Object { Write-Output $_.Line.Trim() }
  exit 0
}
Get-Content -LiteralPath $Path -Tail $Lines
