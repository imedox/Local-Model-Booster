# SYNOPSIS: Detect project type (.NET, Python, Node) and run build/test with timeouts; prints an evidence table
# USAGE: bt run-checks [-Path .] [-Kind build|test|all] [-Filter name] [-TimeoutSec 600]
param(
  [string]$Path = '.',
  [ValidateSet('build', 'test', 'all')][string]$Kind = 'all',
  [string]$Filter = '',
  [int]$TimeoutSec = 600
)
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path
$runner = Join-Path $PSScriptRoot 'run-limited.ps1'
$cmds = @()
$sln = Get-ChildItem -LiteralPath $root -Recurse -Depth 2 -File -Include *.sln | Select-Object -First 1
$proj = Get-ChildItem -LiteralPath $root -Recurse -Depth 2 -File -Include *.csproj | Select-Object -First 1
$target = $null
if ($sln) { $target = $sln.FullName } elseif ($proj) { $target = $proj.FullName }
if ($target) {
  if ($Kind -ne 'test') { $cmds += , @('build', ('dotnet build "' + $target + '" -v minimal --nologo')) }
  if ($Kind -ne 'build') {
    $t = 'dotnet test "' + $target + '" --nologo'
    if ($Filter) { $t += ' --filter "' + $Filter + '"' }
    $cmds += , @('test', $t)
  }
} elseif ((Test-Path -LiteralPath (Join-Path $root 'package.json'))) {
  if ($Kind -ne 'test') { $cmds += , @('build', 'npm run build --if-present') }
  if ($Kind -ne 'build') { $cmds += , @('test', 'npm test --silent') }
} elseif ((Test-Path -LiteralPath (Join-Path $root 'pyproject.toml')) -or (Test-Path -LiteralPath (Join-Path $root 'requirements.txt')) -or (Test-Path -LiteralPath (Join-Path $root 'pytest.ini')) -or (Test-Path -LiteralPath (Join-Path $root 'tests'))) {
  if ($Kind -ne 'test') { $cmds += , @('build', 'python -m compileall -q .') }
  if ($Kind -ne 'build') {
    $t = 'python -m pytest -x -q'
    if ($Filter) { $t += ' -k "' + $Filter + '"' }
    $cmds += , @('test', $t)
  }
} else {
  Write-Output 'No .NET, Node, or Python project detected. Use run-limited with the project''s own command.'
  exit 2
}
$rows = @()
$failed = $false
foreach ($c in $cmds) {
  Write-Output ('>>> ' + $c[1])
  & $runner -Command $c[1] -WorkDir $root -TimeoutSec $TimeoutSec -MaxLines 40
  $code = $LASTEXITCODE
  if ($code -eq 0) { $res = 'passed' } elseif ($code -eq 124) { $res = 'timeout' } else { $res = 'failed' }
  if ($code -ne 0) { $failed = $true }
  $rows += [pscustomobject]@{ Check = $c[0]; Command = $c[1]; Exit = $code; Result = $res }
}
Write-Output ''
Write-Output '== EVIDENCE TABLE =='
$rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
if ($failed) { exit 1 }
exit 0
