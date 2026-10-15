# SYNOPSIS: Report BOM and line endings (CRLF/LF/MIXED) of files; optionally convert with -Fix LF|CRLF
# USAGE: bt line-endings [-Path .] [-Include "*.cs,*.py"] [-Fix none|LF|CRLF] [-Max 200]
param(
  [string]$Path = '.',
  [string]$Include = '*.cs,*.py,*.js,*.ts,*.json,*.md,*.xml,*.axaml,*.xaml,*.csproj,*.props,*.ps1,*.txt,*.cpp,*.h,*.c,*.yml,*.yaml',
  [ValidateSet('none', 'LF', 'CRLF')][string]$Fix = 'none',
  [int]$Max = 200
)
$ErrorActionPreference = 'SilentlyContinue'
$latin1 = [Text.Encoding]::GetEncoding(28591)
$root = (Resolve-Path -LiteralPath $Path).Path
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|\.idea|\.agent|packages)(\\|$)'
$inc = @($Include -split '[,;]' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
if (Test-Path -LiteralPath $root -PathType Leaf) { $files = @(Get-Item -LiteralPath $root); $base = Split-Path $root -Parent } else { $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force; $base = $root }
$shown = 0
foreach ($f in $files) {
  if ($f.Length -gt 2MB -or $f.Length -eq 0) { continue }
  $rel = $f.FullName.Substring($base.Length)
  if ($rel -match $skipRe) { continue }
  $ok = $false
  foreach ($i in $inc) { if ($f.Name -like $i) { $ok = $true } }
  if (-not $ok) { continue }
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $t = $latin1.GetString($bytes)
  $crlf = [regex]::Matches($t, "\r\n").Count
  $lf = [regex]::Matches($t, "(?<!\r)\n").Count
  if ($crlf -gt 0 -and $lf -gt 0) { $kind = 'MIXED' } elseif ($crlf -gt 0) { $kind = 'CRLF' } elseif ($lf -gt 0) { $kind = 'LF' } else { $kind = 'NONE' }
  $note = ''
  if ($Fix -ne 'none' -and $kind -ne 'NONE' -and $kind -ne $Fix) {
    if ($Fix -eq 'CRLF') { $nt = [regex]::Replace($t, "(?<!\r)\n", "`r`n") } else { $nt = $t.Replace("`r`n", "`n") }
    [IO.File]::WriteAllBytes($f.FullName, $latin1.GetBytes($nt))
    $note = ' -> converted to ' + $Fix
  }
  Write-Output ('{0,-6} BOM={1,-5} CRLF={2,-5} LF={3,-5} {4}{5}' -f $kind, $bom, $crlf, $lf, $rel.TrimStart('\'), $note)
  $shown++
  if ($shown -ge $Max) { Write-Output "... stopped at $Max files"; break }
}
if ($shown -eq 0) { Write-Output 'no matching files' }
