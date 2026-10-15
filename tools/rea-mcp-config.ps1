# SYNOPSIS: Generate (or merge into) an MCP config entry for REA on Windows; mode-aware (with-ida / without-ida)
# USAGE: bt rea-mcp-config [-IdaConfig C:\analysis\ida-mcp.json] [-Provider ghidra|hopper] [-Version latest] [-Out "$env:USERPROFILE\.lmstudio\mcp.json"]
param([string]$IdaConfig = '', [string]$Provider = '', [string]$Version = 'latest', [string]$Out = '')
$ErrorActionPreference = 'Stop'
$mf = Join-Path (Join-Path (Join-Path (Get-Location).Path '.agent') 're') 'MODE.txt'
$modeParts = @()
if (Test-Path -LiteralPath $mf) { $modeParts = @((Get-Content -LiteralPath $mf -TotalCount 1) -split '\|') }
if ($modeParts.Count -lt 2 -or ($modeParts[0] -ne 'with-ida' -and $modeParts[0] -ne 'without-ida') -or $modeParts[1] -ne 'yes') {
  Write-Output 'RE MODE NOT SET. STOP. Ask the user: reverse engineering WITH IDA Pro MCP or WITHOUT IDA, and confirm they own or are authorized to analyze the target. Then run: bt re-mode -Set with-ida|without-ida -Authorized yes'
  exit 5
}
$reMode = $modeParts[0]
$env_ = [ordered]@{}
if ($reMode -eq 'with-ida') {
  if (-not $IdaConfig -or -not (Test-Path -LiteralPath $IdaConfig)) { Write-Output 'with-ida needs -IdaConfig <existing ida-mcp.json> (the registration for the user''s own ida-pro-mcp). Validate it with: bt rea-doctor -IdaConfig <file>'; exit 2 }
  $env_['REA_IDA_MCP_CONFIG'] = ((Resolve-Path -LiteralPath $IdaConfig).Path -replace '\\', '/')
  $env_['REA_ANALYSIS_PROVIDER'] = 'ida'
} elseif ($Provider) {
  if ($Provider -ne 'ghidra' -and $Provider -ne 'hopper') { Write-Output 'without-ida: -Provider must be ghidra or hopper (or omit it)'; exit 2 }
  $env_['REA_ANALYSIS_PROVIDER'] = $Provider
}
$entry = [ordered]@{ command = 'cmd.exe'; args = @('/d', '/c', 'npx', '-y', ('rea-agents@' + $Version), 'mcp') }
if ($env_.Count -gt 0) { $entry['env'] = $env_ }
$root = [ordered]@{ mcpServers = [ordered]@{ rea = $entry } }
$json = $root | ConvertTo-Json -Depth 8
Write-Output "# mode: $reMode"
Write-Output $json
if ($Out) {
  if (Test-Path -LiteralPath $Out) {
    try { $cfg = Get-Content -LiteralPath $Out -Raw | ConvertFrom-Json } catch { Write-Output "REFUSED: existing file is not valid JSON: $Out"; exit 3 }
    $bak = $Out + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $Out -Destination $bak
    Write-Output "backup: $bak"
    if (-not $cfg) { $cfg = New-Object psobject }
    if (-not $cfg.mcpServers) { $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object psobject) -Force }
    $cfg.mcpServers | Add-Member -NotePropertyName rea -NotePropertyValue ([pscustomobject]$entry) -Force
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Out -Encoding UTF8
  } else {
    $dir = Split-Path -Parent $Out
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $json | Set-Content -LiteralPath $Out -Encoding UTF8
  }
  Write-Output "written: $Out  (restart the MCP host / reload servers). Keep only the MCP servers you need enabled: REA exposes many tools and costs context."
}
