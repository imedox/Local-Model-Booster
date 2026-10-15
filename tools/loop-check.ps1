# SYNOPSIS: Record each tool call or error text and warn when the same action repeats (loop detector)
# USAGE: bt loop-check -Record "dotnet build -> error CS0103 foo" [-Threshold 2] | -Show | -Reset
param(
  [string]$Record = '',
  [int]$Threshold = 2,
  [int]$Window = 20,
  [switch]$Show,
  [switch]$Reset,
  [string]$Path = '.'
)
$ErrorActionPreference = 'SilentlyContinue'
$agent = Join-Path (Resolve-Path -LiteralPath $Path).Path '.agent'
if (-not (Test-Path -LiteralPath $agent)) { New-Item -ItemType Directory -Path $agent | Out-Null }
$log = Join-Path $agent 'calls.log'
if ($Reset) { Remove-Item -LiteralPath $log -Force; Write-Output 'call log cleared'; exit 0 }
if ($Show) { if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Tail 10 } else { Write-Output '(empty)' }; exit 0 }
if (-not $Record) { Write-Output 'need -Record "text"'; exit 2 }
$norm = ($Record.ToLower() -replace '\s+', ' ').Trim()
$sha = [Security.Cryptography.SHA1]::Create()
$hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($norm)))).Replace('-', '').Substring(0, 12)
$short = $norm
if ($short.Length -gt 100) { $short = $short.Substring(0, 100) }
Add-Content -LiteralPath $log -Value ((Get-Date -Format 'HH:mm:ss') + '|' + $hash + '|' + $short)
$recent = @(Get-Content -LiteralPath $log -Tail $Window)
$n = @($recent | Where-Object { $_.Split('|')[1] -eq $hash }).Count
if ($n -ge $Threshold) {
  Write-Output "LOOP-WARNING: this action was recorded $n times in the last $Window. Apply loop-guard: STOP, write tried/happened/known, name the false assumption, switch strategy."
  exit 3
}
Write-Output "OK (seen $n time)"
