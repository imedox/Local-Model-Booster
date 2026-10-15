# SYNOPSIS: Generate a compact repo map (manifests, layout, extensions, entry points, tests, recent commits)
# USAGE: bt repo-map [-Path .] [-Depth 2] [-Out .agent\REPO_MAP.md]
param([string]$Path = '.', [int]$Depth = 2, [string]$Out = '')
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|\.idea|\.agent|packages)(\\|$)'
$items = New-Object System.Collections.Generic.List[object]
foreach ($f in (Get-ChildItem -LiteralPath $root -Recurse -File -Force)) {
  $rel = $f.FullName.Substring($root.Length)
  if ($rel -match $skipRe) { continue }
  $items.Add([pscustomobject]@{ Rel = $rel.TrimStart('\'); Ext = $f.Extension.ToLower(); Name = $f.Name })
  if ($items.Count -ge 20000) { break }
}
$L = New-Object System.Collections.Generic.List[string]
$L.Add('PROJECT: ' + (Split-Path $root -Leaf) + ' | FILES: ' + $items.Count + ' (capped at 20000)')
$manifestNames = @('package.json', 'pyproject.toml', 'requirements.txt', 'setup.py', 'CMakeLists.txt', 'Cargo.toml', 'go.mod', 'global.json', 'Directory.Build.props', 'Makefile', 'Dockerfile', 'README.md', 'readme.md')
$man = @($items | Where-Object { ($manifestNames -contains $_.Name) -or ($_.Ext -eq '.sln') -or ($_.Ext -eq '.csproj') -or ($_.Ext -eq '.vcxproj') } | Select-Object -First 20)
$L.Add('MANIFESTS: ' + (($man | ForEach-Object { $_.Rel }) -join ' ; '))
$ext = $items | Group-Object Ext | Sort-Object Count -Descending | Select-Object -First 8
$L.Add('EXTENSIONS: ' + (($ext | ForEach-Object { $(if ($_.Name) { $_.Name } else { '(none)' }) + ':' + $_.Count }) -join ' '))
$L.Add('LAYOUT (dir -> file count):')
$dirs = @{}
foreach ($i in $items) {
  $parts = $i.Rel.Split('\')
  if ($parts.Count -gt 1) {
    $n = [Math]::Min($Depth, $parts.Count - 1)
    $k = ($parts[0..($n - 1)]) -join '\'
    if ($dirs.ContainsKey($k)) { $dirs[$k]++ } else { $dirs[$k] = 1 }
  }
}
$dirs.GetEnumerator() | Sort-Object Name | Select-Object -First 30 | ForEach-Object { $L.Add('  ' + $_.Name + ' -> ' + $_.Value) }
$entryNames = @('Program.cs', 'Startup.cs', 'App.axaml', 'App.axaml.cs', 'App.xaml', 'MainWindow.axaml', 'MainWindow.xaml', 'main.py', 'app.py', '__main__.py', 'manage.py', 'index.js', 'index.ts', 'main.ts', 'main.js', 'server.js', 'main.cpp', 'main.c', 'main.rs', 'main.go')
$entry = @($items | Where-Object { $entryNames -contains $_.Name } | Select-Object -First 12)
$L.Add('ENTRY CANDIDATES: ' + (($entry | ForEach-Object { $_.Rel }) -join ' ; '))
$tests = @($items | Where-Object { $_.Rel -match '(^|\\)(tests?|spec|__tests__)(\\|$)|\.tests?\.|_test\.|Tests?\.cs$' })
$L.Add('TESTS: ' + $tests.Count + ' files; e.g. ' + (($tests | Select-Object -First 5 | ForEach-Object { $_.Rel }) -join ' ; '))
if (Get-Command git -ErrorAction SilentlyContinue) {
  $log = @(& git -C $root log --oneline -n 5 2>&1)
  if ($log.Count -gt 0 -and "$($log[0])" -notmatch '^fatal') { $L.Add('RECENT COMMITS:'); foreach ($c in $log) { $L.Add('  ' + $c) } }
}
$L.Add('CONVENTIONS / RISKS: (fill in after reading code)')
if ($Out) {
  $dir = Split-Path -Parent $Out
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content -LiteralPath $Out -Value $L -Encoding UTF8
  Write-Output "written: $Out"
}
$L | ForEach-Object { Write-Output $_ }
