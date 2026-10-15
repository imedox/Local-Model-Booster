# SYNOPSIS: Find stubs and leftovers (TODO, FIXME, NotImplemented, placeholder ellipsis) in code files
# USAGE: bt find-leftovers [-Path .] [-Include "*.cs,*.py"] [-Max 50]
param(
  [string]$Path = '.',
  [string]$Include = '*.cs,*.py,*.js,*.ts,*.cpp,*.h,*.c,*.axaml,*.xaml,*.ps1,*.java,*.go,*.rs',
  [int]$Max = 50
)
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|\.idea|\.agent|packages)(\\|$)'
$re = '(?i)NotImplemented(Exception|Error)?|\bTODO\b|\bFIXME\b|\bHACK\b|\bXXX\b|rest of (the )?(file|code|class)|(remains|stay|stays) unchanged|your code here|<placeholder>|pass\s*#\s*stub|^\s*(//|#)?\s*\.\.\.\s*$'
$inc = @($Include -split '[,;]' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
if (Test-Path -LiteralPath $root -PathType Leaf) { $files = @(Get-Item -LiteralPath $root); $base = Split-Path $root -Parent } else { $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force; $base = $root }
$count = 0
foreach ($f in $files) {
  if ($f.Length -gt 2MB) { continue }
  $rel = $f.FullName.Substring($base.Length)
  if ($rel -match $skipRe) { continue }
  $ok = $false
  foreach ($i in $inc) { if ($f.Name -like $i) { $ok = $true } }
  if (-not $ok) { continue }
  foreach ($m in (Select-String -LiteralPath $f.FullName -Pattern $re)) {
    Write-Output ($rel.TrimStart('\') + ':' + $m.LineNumber + ': ' + $m.Line.Trim())
    $count++
    if ($count -ge $Max) { break }
  }
  if ($count -ge $Max) { Write-Output "... stopped at $Max findings"; break }
}
Write-Output "findings: $count"
if ($count -gt 0) { exit 1 }
