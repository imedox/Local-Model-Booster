# SYNOPSIS: Reverse-engineering gate: record the user's choice (with-ida / without-ida) and authorization
# USAGE: bt re-mode                                   (show current mode)
#        bt re-mode -Clear                            (run at the start of every NEW reverse-engineering request)
#        bt re-mode -Set with-ida|without-ida -Authorized yes   (ONLY after the user answered)
param([string]$Set = '', [string]$Authorized = '', [switch]$Clear, [string]$Path = '.')
$ErrorActionPreference = 'Stop'
$dir = Join-Path (Join-Path (Resolve-Path -LiteralPath $Path).Path '.agent') 're'
$mf = Join-Path $dir 'MODE.txt'
if ($Clear) {
  Remove-Item -LiteralPath $mf -Force -ErrorAction SilentlyContinue
  Write-Output 'MODE cleared. ASK THE USER NOW: reverse engineering WITH IDA Pro MCP or WITHOUT IDA? Also confirm they own or are authorized to analyze the target. Do not run any analysis until they answer.'
  exit 0
}
if ($Set) {
  if ($Set -ne 'with-ida' -and $Set -ne 'without-ida') { Write-Output 'invalid mode: use with-ida or without-ida'; exit 2 }
  if ($Authorized -ne 'yes') { Write-Output 'REFUSED: record the mode only after the user confirmed they own or are authorized to analyze the target (-Authorized yes).'; exit 3 }
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content -LiteralPath $mf -Value ($Set + '|yes|' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding ASCII
  Write-Output "MODE=$Set (user-confirmed, authorization=yes)"
  if ($Set -eq 'with-ida') { Write-Output 'Next: load skill re-with-ida, then rea-reverse-engineering. Verify with: bt rea-doctor -Provider ida -IdaConfig <ida-mcp.json>' }
  else { Write-Output 'Next: load skill re-without-ida, then rea-reverse-engineering.' }
  exit 0
}
if (Test-Path -LiteralPath $mf) { Write-Output ('MODE: ' + (Get-Content -LiteralPath $mf -TotalCount 1)) } else { Write-Output 'MODE: NOT SET -> ask the user (with IDA or without IDA) before any reverse engineering.'; exit 5 }
