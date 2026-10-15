# SYNOPSIS: Run a REA CLI command with timeout and capped output (summary-first, no MCP needed); mode-aware provider rules
# USAGE: bt rea-run -Command analyze-javascript-application -Target "D:\apps\example" [-TimeoutSec 600] [-MaxLines 120]
#        bt rea-run -Command function -Target C:\x\program.exe -Name main -Provider ida|ghidra|hopper
#        bt rea-run -Command doctor [-Provider ida]     |     bt rea-run -Command --help
param(
  [Parameter(Mandatory = $true)][string]$Command,
  [string]$Target = '',
  [string]$Name = '',
  [string]$Provider = '',
  [string]$ExtraArgs = '',
  [int]$TimeoutSec = 600,
  [int]$MaxLines = 120,
  [switch]$NoJson
)
$ErrorActionPreference = 'Stop'
$mf = Join-Path (Join-Path (Join-Path (Get-Location).Path '.agent') 're') 'MODE.txt'
$modeParts = @()
if (Test-Path -LiteralPath $mf) { $modeParts = @((Get-Content -LiteralPath $mf -TotalCount 1) -split '\|') }
if ($modeParts.Count -lt 2 -or ($modeParts[0] -ne 'with-ida' -and $modeParts[0] -ne 'without-ida') -or $modeParts[1] -ne 'yes') {
  Write-Output 'RE MODE NOT SET. STOP. Ask the user: reverse engineering WITH IDA Pro MCP or WITHOUT IDA, and confirm they own or are authorized to analyze the target. Then run: bt re-mode -Set with-ida|without-ida -Authorized yes'
  exit 5
}
$reMode = $modeParts[0]
if ($Command -ne '--help' -and $Command -notmatch '^[a-z][a-z0-9-]*$') { Write-Output 'invalid command name'; exit 2 }
if ($Provider -and @('ida', 'ghidra', 'hopper') -notcontains $Provider) { Write-Output 'provider must be ida, ghidra or hopper'; exit 2 }
if ($reMode -eq 'without-ida' -and $Provider -eq 'ida') { Write-Output 'REFUSED: mode is without-ida. Do not use the IDA provider. Ask the user to change the mode if they want IDA.'; exit 4 }
if ($reMode -eq 'with-ida' -and $Provider -and $Provider -ne 'ida') { Write-Output 'REFUSED: mode is with-ida. Use -Provider ida, or ask the user to change the mode.'; exit 4 }
$nativeCmds = @('function', 'decompile', 'disassemble', 'strings', 'xrefs', 'callers', 'callees', 'search')
if ($nativeCmds -contains $Command -and -not $Provider) { if ($reMode -eq 'with-ida') { $Provider = 'ida' } else { Write-Output 'native commands need -Provider ghidra or hopper in without-ida mode'; exit 2 } }
if ($Target) {
  if (-not (Test-Path -LiteralPath $Target)) { Write-Output "target not found: $Target"; exit 2 }
  $Target = (Resolve-Path -LiteralPath $Target).Path
}
$cli = 'npx -y rea-agents@latest'
if (Get-Command rea -ErrorAction SilentlyContinue) { $cli = 'rea' }
$cmd = "$cli $Command"
if ($Target) { $cmd += ' "' + $Target + '"' }
if ($Name) { $cmd += ' "' + ($Name -replace '"', '') + '"' }
if ($Provider) { $cmd += " --provider $Provider" }
if (-not $NoJson -and $Command -ne '--help') { $cmd += ' --json' }
if ($ExtraArgs) { $cmd += ' ' + $ExtraArgs }
if ($Provider -eq 'ida' -and -not $env:REA_IDA_MCP_CONFIG) { Write-Output 'WARNING: REA_IDA_MCP_CONFIG is not set in this shell. Set it to the user''s ida-mcp.json first (bt rea-doctor -IdaConfig <file>).' }
Write-Output ">>> $cmd   [mode: $reMode]"
& (Join-Path $PSScriptRoot 'run-limited.ps1') -Command $cmd -TimeoutSec $TimeoutSec -MaxLines $MaxLines
exit $LASTEXITCODE
