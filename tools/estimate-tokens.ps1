# SYNOPSIS: Estimate token cost (about chars/4) of files or text and the context zone (Green/Yellow/Red)
# USAGE: bt estimate-tokens -Path a.cs,b.cs [-Used 30000] [-Window 131072]   |   -Text "some text"
param(
  [string[]]$Path,
  [string]$Text = '',
  [int]$Used = 0,
  [int]$Window = 131072
)
$ErrorActionPreference = 'SilentlyContinue'
$inv = [Globalization.CultureInfo]::InvariantCulture
$total = 0
if ($Text) { $t = [int][Math]::Ceiling($Text.Length / 4.0); Write-Output ("text: ~$t tokens"); $total += $t }
foreach ($p in ($Path | ForEach-Object { $_ -split '[,;]' } | Where-Object { $_ })) {
  if (Test-Path -LiteralPath $p -PathType Leaf) {
    $len = (Get-Item -LiteralPath $p).Length
    $t = [int][Math]::Ceiling($len / 4.0)
    Write-Output ('{0,8} tokens  {1}' -f $t, $p)
    $total += $t
  } elseif (Test-Path -LiteralPath $p -PathType Container) {
    $len = (Get-ChildItem -LiteralPath $p -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\(\.git|bin|obj|node_modules|\.venv|dist|build)(\\|$)' } | Measure-Object -Property Length -Sum).Sum
    $t = [int][Math]::Ceiling($len / 4.0)
    Write-Output ('{0,8} tokens  {1} (directory total, do not read it all)' -f $t, $p)
    $total += $t
  } else { Write-Output "not found: $p" }
}
$all = $total + $Used
$pct = [Math]::Round(100.0 * $all / $Window, 1)
if ($pct -lt 50) { $zone = 'GREEN' } elseif ($pct -lt 65) { $zone = 'YELLOW (summarize, avoid big reads)' } else { $zone = 'RED (write STATE.md and compact now)' }
Write-Output ("new: ~$total | already used: $Used | window: $Window | projected: " + $pct.ToString('0.0', $inv) + "% -> $zone")
