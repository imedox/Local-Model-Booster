# SYNOPSIS: Copy files into .agent\backup\<timestamp>\ before risky edits (use when not in a git repo)
# USAGE: bt backup-files -Files "src\a.cs,src\b.cs"
param([Parameter(Mandatory = $true)][string[]]$Files, [string]$Path = '.')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')
$dest = Join-Path (Join-Path (Join-Path $root '.agent') 'backup') (Get-Date -Format 'yyyyMMdd-HHmmss')
$n = 0
foreach ($f in ($Files | ForEach-Object { $_ -split '[,;]' } | Where-Object { $_ })) {
  $full = (Resolve-Path -LiteralPath (Join-Path $root $f) -ErrorAction SilentlyContinue)
  if (-not $full) { $full = Resolve-Path -LiteralPath $f -ErrorAction SilentlyContinue }
  if (-not $full) { Write-Output "missing: $f"; continue }
  $fp = $full.Path
  if (-not $fp.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { Write-Output "skipped (outside project): $fp"; continue }
  $rel = $fp.Substring($root.Length).TrimStart('\')
  $target = Join-Path $dest $rel
  New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
  Copy-Item -LiteralPath $fp -Destination $target
  $n++
}
Write-Output "backed up $n file(s) to $dest"
