# SYNOPSIS: Exact arithmetic for completion % and function quality score (do not compute these in your head)
# USAGE: bt calc-score -Criteria "3:100!,2:50,1:0"     (weight:progress, ! = mandatory)
#        bt calc-score -Scores "A=8,B=9,C=7,D=8,E=7,F=7,G=8,H=6" [-Cap 4]
param([string]$Criteria = '', [string]$Scores = '', [double]$Cap = 0)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
function P([string]$s) { [double]::Parse($s, $inv) }
if ($Criteria) {
  $sw = 0.0; $sp = 0.0; $i = 0; $mand = @()
  foreach ($c in ($Criteria -split ',')) {
    $c = $c.Trim()
    if (-not ($c -match '^(\d+(\.\d+)?):(\d+(\.\d+)?)(!?)$')) { Write-Output "bad item '$c' (use weight:progress[!])"; exit 2 }
    $i++
    $w = P $Matches[1]; $p = P $Matches[3]
    if ($p -lt 0 -or $p -gt 100) { Write-Output "progress out of range in '$c'"; exit 2 }
    $sw += $w; $sp += $w * $p
    if ($Matches[5] -eq '!' -and $p -lt 100) { $mand += "#$i ($p%)" }
  }
  if ($sw -le 0) { Write-Output 'total weight is zero'; exit 2 }
  $o = $sp / $sw
  Write-Output ('OVERALL COMPLETION: ' + $o.ToString('0.0', $inv) + '%')
  if ($mand.Count -gt 0) { Write-Output ('MANDATORY INCOMPLETE: ' + ($mand -join ', ') + ' -> task is NOT complete') } else { Write-Output 'mandatory items: none incomplete' }
}
if ($Scores) {
  $w = @{ A = 25; B = 20; C = 15; D = 15; E = 7; F = 7; G = 8; H = 3 }
  $s = @{}
  foreach ($c in ($Scores -split ',')) {
    $kv = $c.Trim() -split '='
    if ($kv.Count -ne 2 -or -not $w.ContainsKey($kv[0].ToUpper())) { Write-Output "bad item '$c' (use A=8,B=9,...)"; exit 2 }
    $v = P $kv[1]
    if ($v -lt 0 -or $v -gt 10) { Write-Output "score out of range in '$c'"; exit 2 }
    $s[$kv[0].ToUpper()] = $v
  }
  foreach ($k in $w.Keys) { if (-not $s.ContainsKey($k)) { Write-Output "missing criterion $k"; exit 2 } }
  $raw = 0.0
  foreach ($k in $w.Keys) { $raw += $w[$k] * $s[$k] }
  $raw = [Math]::Round($raw / 100.0, 1)
  $final = $raw
  if ($Cap -gt 0 -and $Cap -lt $raw) { $final = $Cap }
  Write-Output ('RAW SCORE: ' + $raw.ToString('0.0', $inv) + ' | CAP: ' + $(if ($Cap -gt 0) { $Cap.ToString('0.0', $inv) } else { 'none' }) + ' | FINAL: ' + $final.ToString('0.0', $inv) + '/10')
  if ($final -lt 8.0) { Write-Output 'Below 8.0: list top 3 improvements, fix confirmed defects, rerun checks, rescore once.' }
}
if (-not $Criteria -and -not $Scores) { Write-Output 'need -Criteria or -Scores'; exit 2 }
