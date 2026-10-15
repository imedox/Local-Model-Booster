# SYNOPSIS: Check readiness for REA (Node, npx, IDA, Ghidra, Java, env vars); optionally run REA's own doctor for a provider
# USAGE: bt rea-doctor [-Provider ida|ghidra|hopper] [-IdaConfig C:\analysis\ida-mcp.json]
param([string]$Provider = '', [string]$IdaConfig = '')
$ErrorActionPreference = 'SilentlyContinue'
Write-Output '== Node / npm (REA needs Node 22.19+, 24.11+, or 26+) =='
$nv = ''
if (Get-Command node) { $nv = (& node --version 2>&1 | Select-Object -First 1) }
if ($nv -match '^v(\d+)\.(\d+)') {
  $maj = [int]$Matches[1]; $min = [int]$Matches[2]
  $ok = (($maj -eq 22 -and $min -ge 19) -or ($maj -eq 24 -and $min -ge 11) -or ($maj -ge 26))
  if ($ok) { Write-Output "node $nv : OK" } else { Write-Output "node $nv : NOT SUPPORTED by REA. Install Node 22.19+/24.11+/26+." }
} else { Write-Output 'node : NOT FOUND' }
foreach ($t in @('npm', 'npx', 'rea', 'java', 'python', 'uv')) {
  if (Get-Command $t) { Write-Output ("{0,-7}: found" -f $t) } else { Write-Output ("{0,-7}: not found" -f $t) }
}
Write-Output '== Environment variables =='
foreach ($v in @('REA_ANALYSIS_PROVIDER', 'REA_IDA_MCP_CONFIG', 'REA_GHIDRA_STARTUP_TIMEOUT_MS', 'REA_HOPPER_STARTUP_TIMEOUT_MS', 'GHIDRA_INSTALL_DIR', 'IDADIR', 'REA_JEB_MCP_URL')) {
  $val = [Environment]::GetEnvironmentVariable($v)
  if ($val) { Write-Output ("{0} = {1}" -f $v, $val) } else { Write-Output ("{0} : (not set)" -f $v) }
}
Write-Output '== IDA (user-licensed; REA never installs it) =='
$ida = @()
if ($env:IDADIR -and (Test-Path -LiteralPath $env:IDADIR)) { $ida += $env:IDADIR }
foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, 'C:\')) { if ($base) { $ida += @(Get-ChildItem -LiteralPath $base -Directory -Filter 'IDA*' | ForEach-Object { $_.FullName }) } }
$cfg = Join-Path $env:APPDATA 'Hex-Rays\IDA Pro\ida-config.json'
if (Test-Path -LiteralPath $cfg) { Write-Output "ida-config.json: $cfg" }
if ($ida.Count -gt 0) { $ida | Select-Object -Unique | ForEach-Object { Write-Output "IDA folder: $_" } } else { Write-Output 'IDA folder: none detected' }
if (Get-Command python) {
  $pk = (& python -m pip show ida-pro-mcp 2>&1 | Select-String '^(Name|Version):' | ForEach-Object { $_.Line }) -join ' '
  if ($pk) { Write-Output "ida-pro-mcp (pip): $pk" } else { Write-Output 'ida-pro-mcp (pip): not installed in the active python' }
}
Write-Output '== Ghidra / Java =='
$gh = @()
if ($env:GHIDRA_INSTALL_DIR -and (Test-Path -LiteralPath $env:GHIDRA_INSTALL_DIR)) { $gh += $env:GHIDRA_INSTALL_DIR }
foreach ($base in @($env:ProgramFiles, 'C:\', (Join-Path $env:USERPROFILE 'tools'))) { if ($base -and (Test-Path -LiteralPath $base)) { $gh += @(Get-ChildItem -LiteralPath $base -Directory -Filter 'ghidra*' | ForEach-Object { $_.FullName }) } }
if ($gh.Count -gt 0) { $gh | Select-Object -Unique | ForEach-Object { Write-Output "Ghidra folder: $_" } } else { Write-Output 'Ghidra folder: none detected' }
if (Get-Command java) { Write-Output ('java: ' + (& java -version 2>&1 | Select-Object -First 1)) }
if ($IdaConfig) {
  Write-Output '== IDA MCP config check =='
  if (-not (Test-Path -LiteralPath $IdaConfig)) { Write-Output "NOT FOUND: $IdaConfig" }
  else {
    try {
      $j = Get-Content -LiteralPath $IdaConfig -Raw | ConvertFrom-Json
      $names = @(); if ($j.mcpServers) { $names = @($j.mcpServers.PSObject.Properties | ForEach-Object { $_.Name }) }
      if ($names.Count -gt 0) { Write-Output ('valid JSON; mcpServers entries: ' + ($names -join ', ')) } else { Write-Output 'valid JSON but no mcpServers object (native bridge profiles use protocol "native": see docs/ida-provider.md)' }
      if ($names.Count -gt 0 -and -not ($names | Where-Object { $_ -match 'ida' })) { Write-Output 'WARNING: no entry name contains "ida" (REA expects an ida-pro-mcp entry)' }
    } catch { Write-Output ('INVALID JSON: ' + $_.Exception.Message) }
  }
}
if ($Provider) {
  Write-Output "== REA doctor --provider $Provider =="
  if ($IdaConfig -and $Provider -eq 'ida') { $env:REA_IDA_MCP_CONFIG = ($IdaConfig -replace '\\', '/') ; $env:REA_ANALYSIS_PROVIDER = 'ida' }
  & (Join-Path $PSScriptRoot 'run-limited.ps1') -Command "npx -y rea-agents@latest doctor --provider $Provider --json" -TimeoutSec 240 -MaxLines 60
}
Write-Output 'NOTE: IDA and its MCP server are installed and licensed by the user. REA does not install, activate, or license them.'
