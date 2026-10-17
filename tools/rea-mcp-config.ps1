# SYNOPSIS: Generate (or merge into) an MCP config entry for REA Meta-Gateway on Windows (LM Studio & Bionic)
# USAGE: bt rea-mcp-config [-IdaConfig C:\analysis\ida-mcp.json] [-Provider ghidra|hopper] [-RawRea] [-Out "$env:USERPROFILE\.lmstudio\mcp.json"]
param(
  [string]$IdaConfig = '',
  [string]$Provider = '',
  [string]$Version = 'latest',
  [string]$Out = '',
  [switch]$RawRea
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
$env_ = [ordered]@{}
if ($reMode -eq 'with-ida') {
  if (-not $IdaConfig -or -not (Test-Path -LiteralPath $IdaConfig)) { Write-Output 'with-ida needs -IdaConfig <existing ida-mcp.json> (the registration for the user''s own ida-pro-mcp). Validate it with: bt rea-doctor -IdaConfig <file>'; exit 2 }
  $env_['REA_IDA_MCP_CONFIG'] = ((Resolve-Path -LiteralPath $IdaConfig).Path -replace '\\', '/')
  $env_['REA_ANALYSIS_PROVIDER'] = 'ida'
} elseif ($Provider) {
  if ($Provider -ne 'ghidra' -and $Provider -ne 'hopper') { Write-Output 'without-ida: -Provider must be ghidra or hopper (or omit it)'; exit 2 }
  $env_['REA_ANALYSIS_PROVIDER'] = $Provider
}

# Determine gateway script path
$gatewayScript = "C:\tools\rea_gateway_mcp.py"
if (-not (Test-Path $gatewayScript)) {
  $candidate = Join-Path $PSScriptRoot "rea_gateway_mcp.py"
  if (Test-Path $candidate) { $gatewayScript = $candidate }
}

if ($RawRea) {
  Write-Warning "WARNING: Raw REA exposes 207 tools (~260,000 tokens) which will cause context overflow on 128k local models!"
  $entry = [ordered]@{ command = 'cmd.exe'; args = @('/d', '/c', 'npx', '-y', ('rea-agents@' + $Version), 'mcp') }
} else {
  $entry = [ordered]@{ command = 'python'; args = @($gatewayScript) }
}
if ($env_.Count -gt 0) { $entry['env'] = $env_ }

$root = [ordered]@{ mcpServers = [ordered]@{ 'rea-gateway' = $entry } }
$json = $root | ConvertTo-Json -Depth 8
Write-Output "# mode: $reMode"
Write-Output "# configuration: $(if ($RawRea) { 'Raw REA (207 tools)' } else { 'REA Meta-Gateway (5 tools, NVMe SQLite FTS5)' })"
Write-Output $json

# Helper function to merge into standard mcpServers JSON (LM Studio)
function Merge-McpJson([string]$filePath, [string]$serverName, $serverEntry) {
  if (Test-Path -LiteralPath $filePath) {
    try { $cfg = Get-Content -LiteralPath $filePath -Raw | ConvertFrom-Json } catch { Write-Output "REFUSED: existing file is not valid JSON: $filePath"; return }
    $bak = $filePath + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $filePath -Destination $bak
    Write-Output "backup: $bak"
    if (-not $cfg) { $cfg = New-Object psobject }
    if (-not $cfg.mcpServers) { $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object psobject) -Force }
    $cfg.mcpServers | Add-Member -NotePropertyName $serverName -NotePropertyValue ([pscustomobject]$serverEntry) -Force
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $filePath -Encoding UTF8
    Write-Output "updated: $filePath -> registered '$serverName'"
  } else {
    $dir = Split-Path -Parent $filePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    [ordered]@{ mcpServers = [ordered]@{ $serverName = $serverEntry } } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $filePath -Encoding UTF8
    Write-Output "written: $filePath -> registered '$serverName'"
  }
}

# Helper function to merge into Bionic internal registry (ng-mcp.json)
function Merge-BionicMcp([string]$filePath, [string]$serverName, $serverEntry) {
  $dir = Split-Path -Parent $filePath
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  
  $bionicMcp = @{ servers = @() }
  if (Test-Path -LiteralPath $filePath) {
    try {
      $raw = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
      if ($raw.Trim()) { $bionicMcp = $raw | ConvertFrom-Json }
    } catch {}
    $bak = $filePath + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $filePath -Destination $bak
    Write-Output "backup: $bak"
  }
  
  $serversList = [System.Collections.Generic.List[PSObject]]::new()
  $found = $false
  
  if ($bionicMcp.servers) {
    foreach ($srv in $bionicMcp.servers) {
      if ($srv.name -ieq "rea" -or $srv.name -ieq "rea-gateway" -or $srv.name -ieq $serverName) {
        $srv.name = "REA"
        $srv.enabled = $true
        $srv.connection = [PSCustomObject]@{
          type = "stdio"
          command = $serverEntry.command
          args = $serverEntry.args
          env = if ($serverEntry.Contains('env')) { [PSCustomObject]$serverEntry.env } else { [PSCustomObject]@{} }
        }
        $found = $true
        $serversList.Add($srv)
      } else {
        $serversList.Add($srv)
      }
    }
  }
  
  if (-not $found) {
    $serversList.Add([PSCustomObject]@{
      id = [System.Guid]::NewGuid().ToString()
      name = "REA"
      enabled = $true
      connection = [PSCustomObject]@{
        type = "stdio"
        command = $serverEntry.command
        args = $serverEntry.args
        env = if ($serverEntry.Contains('env')) { [PSCustomObject]$serverEntry.env } else { [PSCustomObject]@{} }
      }
    })
  }
  
  $result = [PSCustomObject]@{ servers = $serversList.ToArray() }
  $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $filePath -Encoding UTF8
  Write-Output "updated Bionic: $filePath -> configured 'REA' ($($serverEntry.command) $($serverEntry.args -join ' '))"
}

if ($Out) {
  Merge-McpJson -filePath $Out -serverName 'rea-gateway' -serverEntry $entry
} else {
  # Default: update both LM Studio and Bionic
  $lmMcp = Join-Path $env:USERPROFILE ".lmstudio\mcp.json"
  Merge-McpJson -filePath $lmMcp -serverName 'rea-gateway' -serverEntry $entry
  
  $bionicMcp = Join-Path $env:USERPROFILE ".lmstudio\apps\bionic\.internal\ng-mcp.json"
  Merge-BionicMcp -filePath $bionicMcp -serverName 'REA' -serverEntry $entry
}
