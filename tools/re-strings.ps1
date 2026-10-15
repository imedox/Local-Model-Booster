# SYNOPSIS: Extract printable strings (ASCII and UTF-16LE) from a file with offsets, presets and caps (no IDA needed)
# USAGE: bt re-strings -Path file.exe [-MinLen 6] [-Preset url|path|ip|email|registry|cmd|key] [-Filter "regex"] [-Unicode] [-Max 150] [-MaxMB 64]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [int]$MinLen = 6,
  [string]$Preset = '',
  [string]$Filter = '',
  [switch]$Unicode,
  [int]$Max = 150,
  [int]$MaxMB = 64
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
$f = (Resolve-Path -LiteralPath $Path).Path
$presets = @{
  url      = 'https?://[^\s"''<>]+'
  path     = '(?i)([A-Z]:\\[^\s"''<>|]{3,}|/(usr|etc|var|tmp|home)/[^\s"''<>]{3,})'
  ip       = '\b(\d{1,3}\.){3}\d{1,3}\b'
  email    = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  registry = '(?i)(HKEY_[A-Z_]+|HKLM\\|HKCU\\|SOFTWARE\\)[^\s"'']*'
  cmd      = '(?i)(cmd\.exe|powershell|rundll32|regsvr32|schtasks|wmic|certutil|bitsadmin|curl |wget )'
  key      = '(?i)(api[_-]?key|secret|token|passw(or)?d|bearer |authorization|BEGIN [A-Z ]*PRIVATE KEY)'
}
$re = $Filter
if ($Preset) { if (-not $presets.ContainsKey($Preset)) { Write-Output ('unknown preset; use: ' + (($presets.Keys | Sort-Object) -join ', ')); exit 2 }; $re = $presets[$Preset] }
$latin1 = [Text.Encoding]::GetEncoding(28591)
$fs = [IO.File]::Open($f, 'Open', 'Read', 'ReadWrite')
$limit = [int64]$MaxMB * 1MB
$chunk = 8MB
$seen = @{}
$count = 0
$scanned = 0
try {
  $pos = [int64]0
  while ($pos -lt $fs.Length -and $pos -lt $limit -and $count -lt $Max) {
    $fs.Position = $pos
    $n = [int][Math]::Min($chunk, $fs.Length - $pos)
    $buf = New-Object byte[] $n
    $got = $fs.Read($buf, 0, $n)
    $s = $latin1.GetString($buf, 0, $got)
    $scanned += $got
    if ($Unicode) { $pat = '(?:[\x20-\x7E]\x00){' + $MinLen + ',}' } else { $pat = '[\x20-\x7E]{' + $MinLen + ',}' }
    foreach ($m in [regex]::Matches($s, $pat)) {
      $txt = $m.Value
      if ($Unicode) { $txt = $txt.Replace([string][char]0, '') }
      if ($re -and $txt -notmatch $re) { continue }
      if ($txt.Length -gt 200) { $txt = $txt.Substring(0, 200) + '...' }
      if ($seen.ContainsKey($txt)) { continue }
      $seen[$txt] = $true
      Write-Output ('0x{0:X8}: {1}' -f ($pos + $m.Index), $txt)
      $count++
      if ($count -ge $Max) { break }
    }
    $pos += $got
    if ($got -le 0) { break }
  }
} finally { $fs.Close() }
Write-Output ("strings shown: $count | bytes scanned: $scanned of " + (Get-Item -LiteralPath $f).Length + ' (strings spanning 8 MB chunk borders may be split)')
if ($count -ge $Max) { Write-Output "... capped at $Max; add -Preset/-Filter or raise -Max" }
Write-Output 'Strings are observations of bytes in the file, not proof the code path runs.'
