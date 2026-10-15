# SYNOPSIS: Run a command with timeout, output cap, destructive-command block and evidence log
# USAGE: bt run-limited -Command "dotnet build -v minimal" [-TimeoutSec 120] [-MaxLines 80] [-WorkDir .] [-AllowDestructive]
param(
  [Parameter(Mandatory = $true)][string]$Command,
  [int]$TimeoutSec = 120,
  [int]$MaxLines = 80,
  [string]$WorkDir = '.',
  [switch]$AllowDestructive
)
$ErrorActionPreference = 'Continue'
$inv = [Globalization.CultureInfo]::InvariantCulture
$blocked = @('diskpart', '(^|\s)format\s+[A-Za-z]:', '\brmdir\s+/s', '\brd\s+/s', '\bdel\s+/[sfqSFQ]', 'Remove-Item.*-Recurse', 'git\s+reset\s+--hard', 'git\s+clean', 'git\s+push.*--force', '\breg\s+(add|delete)', 'Stop-Computer', 'Restart-Computer', '\bshutdown\b')
if (-not $AllowDestructive) {
  foreach ($b in $blocked) {
    if ($Command -match $b) {
      Write-Output "BLOCKED: command matches destructive pattern '$b'. Get explicit user authorization, then rerun with -AllowDestructive."
      exit 4
    }
  }
}
$wd = (Resolve-Path -LiteralPath $WorkDir).Path
$o = [IO.Path]::GetTempFileName()
$e = [IO.Path]::GetTempFileName()
$sw = [Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/d', '/c', $Command) -WorkingDirectory $wd -NoNewWindow -PassThru -RedirectStandardOutput $o -RedirectStandardError $e
$null = $p.Handle
$done = $p.WaitForExit($TimeoutSec * 1000)
if (-not $done) {
  & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
  $code = 124; $status = 'timeout'
} else {
  $p.WaitForExit()
  $code = $p.ExitCode
  if ($code -eq 0) { $status = 'passed' } else { $status = 'failed' }
}
$sw.Stop()
$lines = @()
$lines += @(Get-Content -LiteralPath $o -ErrorAction SilentlyContinue)
$lines += @(Get-Content -LiteralPath $e -ErrorAction SilentlyContinue)
Remove-Item -LiteralPath $o, $e -Force -ErrorAction SilentlyContinue
if ($lines.Count -gt $MaxLines) {
  Write-Output ("--- showing last $MaxLines of " + $lines.Count + ' lines ---')
  $lines = $lines | Select-Object -Last $MaxLines
}
$lines | ForEach-Object { Write-Output $_ }
$secs = $sw.Elapsed.TotalSeconds.ToString('0.0', $inv)
Write-Output "EXIT=$code STATUS=$status TIME=${secs}s"
try {
  $agent = Join-Path $wd '.agent'
  if (-not (Test-Path -LiteralPath $agent)) { New-Item -ItemType Directory -Path $agent | Out-Null }
  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Add-Content -LiteralPath (Join-Path $agent 'evidence.log') -Value "$stamp | $Command | exit=$code | $status"
} catch { }
exit $code
