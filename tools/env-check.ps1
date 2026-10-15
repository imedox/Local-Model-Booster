# SYNOPSIS: Report OS, shell, toolchain versions, git state and GPU VRAM (read-only)
# USAGE: bt env-check
$ErrorActionPreference = 'SilentlyContinue'
Write-Output '== System =='
Write-Output ('OS    : ' + [Environment]::OSVersion.VersionString)
Write-Output ('Shell : PowerShell ' + $PSVersionTable.PSVersion)
Write-Output ('CWD   : ' + (Get-Location).Path)
Write-Output '== Toolchain =='
$tools = [ordered]@{ dotnet = '--version'; python = '--version'; py = '--version'; node = '--version'; npm = '--version'; git = '--version'; rg = '--version'; cmake = '--version'; gcc = '--version'; 'nvidia-smi' = '--version' }
foreach ($n in $tools.Keys) {
  if (Get-Command $n -ErrorAction SilentlyContinue) {
    $out = & $n $tools[$n] 2>&1 | Select-Object -First 1
    Write-Output ('{0,-10} {1}' -f $n, "$out")
  } else {
    Write-Output ('{0,-10} NOT FOUND' -f $n)
  }
}
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
  Write-Output '== dotnet SDKs =='
  & dotnet --list-sdks 2>&1 | Select-Object -First 6
}
Write-Output '== Git =='
if (Get-Command git -ErrorAction SilentlyContinue) {
  $inside = (& git rev-parse --is-inside-work-tree 2>&1) -join ''
  if ($inside -eq 'true') {
    $branch = (& git rev-parse --abbrev-ref HEAD 2>&1) -join ''
    $dirty = @(& git status --porcelain 2>&1).Count
    Write-Output ("branch: $branch | uncommitted entries: $dirty")
  } else { Write-Output 'not inside a git work tree' }
}
Write-Output '== GPU =='
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  & nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>&1
} else { Write-Output 'nvidia-smi not found' }
