# SYNOPSIS: Print the exact REA setup plan for the chosen mode (does NOT run setup; the user approves and runs it)
# USAGE: bt rea-setup-plan [-IdaConfig C:\analysis\ida-mcp.json]
param([string]$IdaConfig = '')
$mf = Join-Path (Join-Path (Join-Path (Get-Location).Path '.agent') 're') 'MODE.txt'
$modeParts = @()
if (Test-Path -LiteralPath $mf) { $modeParts = @((Get-Content -LiteralPath $mf -TotalCount 1) -split '\|') }
if ($modeParts.Count -lt 2 -or ($modeParts[0] -ne 'with-ida' -and $modeParts[0] -ne 'without-ida') -or $modeParts[1] -ne 'yes') {
  Write-Output 'RE MODE NOT SET. STOP. Ask the user: reverse engineering WITH IDA Pro MCP or WITHOUT IDA, and confirm authorization. Then run: bt re-mode -Set with-ida|without-ida -Authorized yes'
  exit 5
}
$m = $modeParts[0]
Write-Output "REA SETUP PLAN (mode: $m). Show this to the user and get approval. Setup writes agent configuration (with backups)."
Write-Output ''
Write-Output '1) Check readiness:'
Write-Output '   bt rea-doctor'
if ($m -eq 'with-ida') {
  $cfg = $IdaConfig; if (-not $cfg) { $cfg = 'C:\analysis\ida-mcp.json' }
  Write-Output '2) User prerequisites (REA does not install these): licensed IDA Pro + a working mrexodia/ida-pro-mcp, and an ida-mcp.json registration.'
  Write-Output '3) In the USER''s PowerShell:'
  Write-Output ('   $env:REA_IDA_MCP_CONFIG = "' + ($cfg -replace '\\', '/') + '"')
  Write-Output '   $env:REA_ANALYSIS_PROVIDER = "ida"'
  Write-Output '   npx -y rea-agents@latest doctor --provider ida --json'
  Write-Output '   npx rea-agents@latest setup'
  Write-Output '4) Or generate a manual MCP entry (LM Studio / Hermes / any MCP host):'
  Write-Output ('   bt rea-mcp-config -IdaConfig "' + $cfg + '" -Out "$env:USERPROFILE\.lmstudio\mcp.json"')
} else {
  Write-Output '2) Without IDA, native depth comes from Ghidra (experimental on Windows) or Hopper; JavaScript/Electron, .NET, APK, archives and websites need no native engine.'
  Write-Output '3) In the USER''s PowerShell:'
  Write-Output '   npx rea-agents@latest setup'
  Write-Output '   (optional) npx -y rea-agents@latest doctor --provider ghidra --json'
  Write-Output '4) Or generate a manual MCP entry:'
  Write-Output '   bt rea-mcp-config -Out "$env:USERPROFILE\.lmstudio\mcp.json"    (add -Provider ghidra if Ghidra is installed)'
}
Write-Output ''
Write-Output 'After MCP registration changes, restart the agent / reload MCP servers. The CLI works immediately: bt rea-run -Command analyze-javascript-application -Target <path>'
Write-Output 'On Windows, stdio clients usually need the npx shim wrapped: cmd.exe /d /c npx -y rea-agents@<version> mcp (the generated entry already does this).'
