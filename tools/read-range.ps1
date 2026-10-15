# SYNOPSIS: Read a line range (or an outline) of a file with line numbers, capped at 400 lines
# USAGE: bt read-range -Path file.cs -Start 100 -End 160   |   -Around 120 [-Lines 60]   |   -Outline
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [int]$Start = 1,
  [int]$End = 0,
  [int]$Around = 0,
  [int]$Lines = 80,
  [switch]$Outline
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Write-Output "File not found: $Path"; exit 2 }
if ($Outline) {
  $re = '^\s*(public|private|protected|internal|static|async|abstract|override|sealed|partial|class|interface|struct|enum|namespace|record|def |function |export |fn |impl |type |#region|using static)\b|^\s*(const|let|var)\s+\w+\s*=\s*(async\s*)?\(|^\s*[A-Za-z_][\w<>\[\],\s\*&:]*\s+[A-Za-z_]\w*\s*\([^;]*\)\s*(\{|$)'
  $n = 0; $shown = 0
  foreach ($l in (Get-Content -LiteralPath $Path)) {
    $n++
    if ($l -match $re) { Write-Output ('{0,5}: {1}' -f $n, $l.TrimEnd()); $shown++; if ($shown -ge 150) { Write-Output '... outline truncated at 150 entries'; break } }
  }
  Write-Output "(total lines scanned: $n)"
  exit 0
}
if ($Around -gt 0) { $half = [int]($Lines / 2); $Start = [Math]::Max(1, $Around - $half); $End = $Around + $half }
if ($End -le 0) { $End = $Start + $Lines - 1 }
if ($End - $Start + 1 -gt 400) { $End = $Start + 399; Write-Output '(range capped at 400 lines)' }
$i = $Start
Get-Content -LiteralPath $Path -TotalCount $End | Select-Object -Skip ($Start - 1) | ForEach-Object {
  Write-Output ('{0,5}: {1}' -f $i, $_)
  $i++
}
