# SYNOPSIS: Keep a reverse-engineering evidence log: observations (OBS), inferences (INF, need a basis), unknowns (UNK)
# USAGE: bt re-evidence -Kind OBS -Claim "imports WinHttpOpen" -Source "re-triage app.exe" -Confidence high
#        bt re-evidence -Kind INF -Claim "app makes HTTP calls" -Basis "E1,E2" -Confidence medium
#        bt re-evidence -Kind UNK -Claim "what the payload decrypts to"   |   -Show   |   -Reset
param(
  [ValidateSet('OBS', 'INF', 'UNK')][string]$Kind = 'OBS',
  [string]$Claim = '',
  [string]$Source = '',
  [string]$Basis = '',
  [ValidateSet('high', 'medium', 'low')][string]$Confidence = 'medium',
  [switch]$Show,
  [switch]$Reset,
  [string]$Path = '.'
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path (Join-Path (Resolve-Path -LiteralPath $Path).Path '.agent') 're'
$file = Join-Path $dir 'EVIDENCE.md'
if ($Reset) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue; Write-Output 'evidence log cleared'; exit 0 }
if ($Show -or -not $Claim) {
  if (-not (Test-Path -LiteralPath $file)) { Write-Output '(no evidence recorded)'; exit 0 }
  $rows = @(Get-Content -LiteralPath $file | Where-Object { $_ -match '^\| E\d+' })
  foreach ($k in 'OBS', 'INF', 'UNK') { Write-Output ($k + ': ' + @($rows | Where-Object { $_ -match ('\| ' + $k + ' \|') }).Count) }
  $rows | Select-Object -Last 20 | ForEach-Object { Write-Output $_ }
  exit 0
}
if ($Kind -eq 'OBS' -and -not $Source) { Write-Output 'REFUSED: an observation needs -Source (tool, file, offset, address, or evidence id).'; exit 3 }
if ($Kind -eq 'INF' -and -not $Basis) { Write-Output 'REFUSED: an inference needs -Basis (comma-separated evidence ids such as E1,E2).'; exit 3 }
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
if (-not (Test-Path -LiteralPath $file)) { Set-Content -LiteralPath $file -Value @('# RE EVIDENCE', '| ID | KIND | CLAIM | SOURCE / BASIS | CONFIDENCE |', '|---|---|---|---|---|') -Encoding UTF8 }
$existing = @(Get-Content -LiteralPath $file | Where-Object { $_ -match '^\| E\d+' })
if ($Kind -eq 'INF') {
  foreach ($b in ($Basis -split '[,;\s]+' | Where-Object { $_ })) {
    if (-not ($existing | Where-Object { $_ -match ('^\| ' + [regex]::Escape($b) + ' \|') })) { Write-Output "REFUSED: basis $b does not exist in the log."; exit 3 }
  }
}
$id = 'E' + ($existing.Count + 1)
$src = $Source; if ($Kind -eq 'INF') { $src = 'basis: ' + $Basis }; if ($Kind -eq 'UNK' -and -not $src) { $src = 'not established' }
$c = ($Claim -replace '\|', '/')
Add-Content -LiteralPath $file -Value ('| ' + $id + ' | ' + $Kind + ' | ' + $c + ' | ' + ($src -replace '\|', '/') + ' | ' + $Confidence + ' |')
Write-Output "recorded $id [$Kind]"
