# SYNOPSIS: Compare two extracted app versions by relative path and SHA256 (added / removed / changed files)
# USAGE: bt re-diff-dirs -Old D:\app-v1 -New D:\app-v2 [-Include "*.js,*.dll"] [-Max 100]
param(
  [Parameter(Mandatory = $true)][string]$Old,
  [Parameter(Mandatory = $true)][string]$New,
  [string]$Include = '',
  [int]$Max = 100
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
function Manifest([string]$dir) {
  $root = (Resolve-Path -LiteralPath $dir).Path.TrimEnd('\')
  $inc = @($Include -split '[,;]' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
  $m = @{}
  $n = 0
  foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File -Force)) {
    if ($inc.Count -gt 0) { $ok = $false; foreach ($i in $inc) { if ($file.Name -like $i) { $ok = $true } }; if (-not $ok) { continue } }
    $rel = $file.FullName.Substring($root.Length).TrimStart('\')
    $m[$rel] = [pscustomobject]@{ Size = $file.Length; Hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
    $n++
    if ($n -ge 5000) { Write-Output ("WARNING: capped at 5000 files in " + $dir); break }
  }
  return $m
}
$a = Manifest $Old
$b = Manifest $New
$added = @($b.Keys | Where-Object { -not $a.ContainsKey($_) } | Sort-Object)
$removed = @($a.Keys | Where-Object { -not $b.ContainsKey($_) } | Sort-Object)
$changed = @($b.Keys | Where-Object { $a.ContainsKey($_) -and $a[$_].Hash -ne $b[$_].Hash } | Sort-Object)
Write-Output ("old files: " + $a.Count + " | new files: " + $b.Count + " | added: " + $added.Count + " | removed: " + $removed.Count + " | changed: " + $changed.Count)
Write-Output '--- ADDED ---';   $added | Select-Object -First $Max | ForEach-Object { Write-Output ('+ ' + $_ + '  (' + $b[$_].Size + ' bytes)') }
Write-Output '--- REMOVED ---'; $removed | Select-Object -First $Max | ForEach-Object { Write-Output ('- ' + $_) }
Write-Output '--- CHANGED ---'; $changed | Select-Object -First $Max | ForEach-Object { Write-Output ('~ ' + $_ + '  (' + $a[$_].Size + ' -> ' + $b[$_].Size + ' bytes)') }
Write-Output 'A changed hash is an observation. What the change means is an inference: inspect the changed files before claiming a feature was added.'
