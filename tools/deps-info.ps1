# SYNOPSIS: Show declared dependencies and target versions from csproj, package.json, requirements.txt and installed pip packages
# USAGE: bt deps-info [-Path .] [-Filter name]
param([string]$Path = '.', [string]$Filter = '')
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|packages)(\\|$)'
$out = New-Object System.Collections.Generic.List[string]
foreach ($f in (Get-ChildItem -LiteralPath $root -Recurse -Depth 3 -File -Force | Where-Object { $_.FullName.Substring($root.Length) -notmatch $skipRe })) {
  $rel = $f.FullName.Substring($root.Length).TrimStart('\')
  if ($f.Extension -in '.csproj', '.props', '.targets') {
    $out.Add("[$rel]")
    foreach ($m in (Select-String -LiteralPath $f.FullName -Pattern 'TargetFramework|LangVersion|Nullable|PackageReference|PackageVersion')) { $out.Add('  ' + $m.Line.Trim()) }
  } elseif ($f.Name -eq 'package.json') {
    $out.Add("[$rel]")
    try {
      $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json
      foreach ($sec in 'dependencies', 'devDependencies') { if ($j.$sec) { foreach ($p in $j.$sec.PSObject.Properties) { $out.Add("  $sec : " + $p.Name + ' ' + $p.Value) } } }
      if ($j.engines) { $out.Add('  engines: ' + ($j.engines | ConvertTo-Json -Compress)) }
    } catch { $out.Add('  (could not parse)') }
  } elseif ($f.Name -like 'requirements*.txt') {
    $out.Add("[$rel]")
    foreach ($l in (Get-Content -LiteralPath $f.FullName | Where-Object { $_ -and $_ -notmatch '^\s*#' })) { $out.Add('  ' + $l.Trim()) }
  } elseif ($f.Name -in 'pyproject.toml', 'global.json') {
    $out.Add("[$rel]")
    foreach ($l in (Get-Content -LiteralPath $f.FullName -TotalCount 60)) { $out.Add('  ' + $l) }
  }
}
if (Get-Command python -ErrorAction SilentlyContinue) {
  $out.Add('[pip list (active python)]')
  foreach ($l in (& python -m pip list --format=freeze 2>&1 | Select-Object -First 80)) { $out.Add('  ' + $l) }
}
if ($Filter) { $res = @($out | Where-Object { $_ -match '^\[' -or $_ -match [regex]::Escape($Filter) }) } else { $res = @($out) }
$res | Select-Object -First 200 | ForEach-Object { Write-Output $_ }
if ($out.Count -eq 0) { Write-Output 'no manifests found' }
