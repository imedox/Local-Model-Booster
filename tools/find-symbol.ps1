# SYNOPSIS: Search code for a symbol or text (uses ripgrep if present), ignoring build dirs, output capped
# USAGE: bt find-symbol -Pattern "ClassName" [-Path .] [-Include "*.cs,*.axaml"] [-Context 2] [-Max 40] [-Literal] [-FilesOnly]
param(
  [Parameter(Mandatory = $true)][string]$Pattern,
  [string]$Path = '.',
  [string]$Include = '',
  [int]$Context = 0,
  [int]$Max = 40,
  [switch]$Literal,
  [switch]$FilesOnly
)
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path
if (Get-Command rg -ErrorAction SilentlyContinue) {
  $a = @('--no-heading', '--max-columns', '200', '--max-columns-preview')
  foreach ($d in @('.git', 'bin', 'obj', 'node_modules', '.venv', 'venv', 'dist', 'build', '__pycache__', '.vs', '.agent')) { $a += @('--glob', "!$d") }
  if ($FilesOnly) { $a += '-l' } else { $a += '-n' }
  if ($Literal) { $a += '-F' }
  if ($Context -gt 0) { $a += @('-C', "$Context") }
  foreach ($g in ($Include -split '[,;]' | Where-Object { $_ })) { $a += @('--glob', $g.Trim()) }
  $a += @('-e', $Pattern, '--', $root)
  $res = @(& rg @a 2>&1 | Select-Object -First ($Max + 1))
  $res | Select-Object -First $Max | ForEach-Object { Write-Output $_ }
  if ($res.Count -gt $Max) { Write-Output "... truncated at $Max lines; narrow the pattern or path" }
  if ($res.Count -eq 0) { Write-Output 'NO MATCHES' }
  exit 0
}
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|\.idea|\.agent|packages)(\\|$)'
$inc = @($Include -split '[,;]' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
if (Test-Path -LiteralPath $root -PathType Leaf) { $files = @(Get-Item -LiteralPath $root); $base = Split-Path $root -Parent } else { $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force; $base = $root }
$count = 0
$trunc = $false
foreach ($f in $files) {
  if ($f.Length -gt 2MB) { continue }
  $rel = $f.FullName.Substring($base.Length)
  if ($rel -match $skipRe) { continue }
  if ($inc.Count -gt 0) { $ok = $false; foreach ($i in $inc) { if ($f.Name -like $i) { $ok = $true } }; if (-not $ok) { continue } }
  if ($Literal) { $m = Select-String -LiteralPath $f.FullName -Pattern $Pattern -SimpleMatch -Context $Context, $Context } else { $m = Select-String -LiteralPath $f.FullName -Pattern $Pattern -Context $Context, $Context }
  if (-not $m) { continue }
  if ($FilesOnly) { Write-Output $rel.TrimStart('\'); $count++; if ($count -ge $Max) { $trunc = $true; break }; continue }
  foreach ($x in $m) {
    foreach ($pre in $x.Context.PreContext) { Write-Output ('  | ' + $pre) }
    Write-Output ($rel.TrimStart('\') + ':' + $x.LineNumber + ': ' + $x.Line.Trim())
    foreach ($post in $x.Context.PostContext) { Write-Output ('  | ' + $post) }
    $count++
    if ($count -ge $Max) { $trunc = $true; break }
  }
  if ($trunc) { break }
}
if ($trunc) { Write-Output "... truncated at $Max results; narrow the pattern or path" }
if ($count -eq 0) { Write-Output 'NO MATCHES' }
