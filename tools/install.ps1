# SYNOPSIS: Install Model-Booster: set BOOSTER_HOME, add tools to user PATH, optionally copy skills to a target folder
# USAGE: powershell -ExecutionPolicy Bypass -File tools\install.ps1 [-SkillsTarget "C:\path\to\skills"] [-AddToPath] [-Uninstall] [-WhatIf]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$SkillsTarget = (Join-Path $env:USERPROFILE '.lmstudio\skills'),
  [switch]$AddToPath,
  [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$home_ = Split-Path -Parent $PSScriptRoot
$tools = $PSScriptRoot
function Get-UserPath { [Environment]::GetEnvironmentVariable('Path', 'User') }
if ($Uninstall) {
  if ($PSCmdlet.ShouldProcess('BOOSTER_HOME', 'remove')) { [Environment]::SetEnvironmentVariable('BOOSTER_HOME', $null, 'User') }
  $parts = @((Get-UserPath) -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $tools.TrimEnd('\')) })
  if ($PSCmdlet.ShouldProcess('user PATH', 'remove tools dir')) { [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User') }
  Write-Output 'Uninstalled env settings (skill folders you copied are left in place). Restart your terminal.'
  exit 0
}
if ($PSCmdlet.ShouldProcess('BOOSTER_HOME', "set to $home_")) { [Environment]::SetEnvironmentVariable('BOOSTER_HOME', $home_, 'User') }
Write-Output "BOOSTER_HOME = $home_"
if ($AddToPath) {
  $parts = @((Get-UserPath) -split ';' | Where-Object { $_ })
  if (-not ($parts | Where-Object { $_.TrimEnd('\') -eq $tools.TrimEnd('\') })) {
    if ($PSCmdlet.ShouldProcess('user PATH', "append $tools")) { [Environment]::SetEnvironmentVariable('Path', (($parts + $tools) -join ';'), 'User') }
    Write-Output "added to user PATH: $tools"
  } else { Write-Output 'tools dir already on user PATH' }
}
if ($SkillsTarget) {
  if (-not (Test-Path -LiteralPath $SkillsTarget)) { New-Item -ItemType Directory -Path $SkillsTarget | Out-Null }
  foreach ($d in (Get-ChildItem -LiteralPath (Join-Path $home_ 'skills') -Directory)) {
    $dst = Join-Path $SkillsTarget $d.Name
    if ($PSCmdlet.ShouldProcess($dst, 'copy skill (overwrites same-named skill)')) { Copy-Item -LiteralPath $d.FullName -Destination $dst -Recurse -Force }
  }
  Write-Output "skills copied to $SkillsTarget (only same-named Model-Booster skills are overwritten)"
}
Write-Output 'Done. Open a NEW terminal, then test: bt list'
