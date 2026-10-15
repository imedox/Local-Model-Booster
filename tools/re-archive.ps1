# SYNOPSIS: List or extract ZIP-based packages (APK, JAR, MSIX/APPX, XPI, NUPKG, ZIP) with flags for interesting entries; zip-slip safe
# USAGE: bt re-archive -Path app.apk [-Max 200] [-Filter "*.dll"] [-Extract D:\out] [-MaxMB 200]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [int]$Max = 200,
  [string]$Filter = '*',
  [string]$Extract = '',
  [int]$MaxMB = 200
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
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$f = (Resolve-Path -LiteralPath $Path).Path
$zip = [IO.Compression.ZipFile]::OpenRead($f)
try {
  $entries = @($zip.Entries | Where-Object { $_.FullName -notmatch '/$' })
  $names = $entries | ForEach-Object { $_.FullName }
  $kind = 'generic ZIP'
  if ($names -contains 'AndroidManifest.xml') { $kind = 'Android APK (decompile needs JADX + full JDK; REA inventory_artifact lists it safely)' }
  elseif ($names -contains 'AppxManifest.xml') { $kind = 'MSIX/APPX package' }
  elseif ($names -contains 'META-INF/MANIFEST.MF') { $kind = 'Java JAR' }
  elseif ($names -contains '[Content_Types].xml') { $kind = 'Office/OPC package' }
  elseif (@($names | Where-Object { $_ -match '(^|/)app\.asar$' }).Count -gt 0) { $kind = 'Electron app bundle (contains app.asar: use bt re-asar)' }
  Write-Output ("ARCHIVE: " + $f)
  Write-Output ("KIND   : " + $kind)
  Write-Output ("ENTRIES: " + $entries.Count + " | uncompressed total: " + [Math]::Round((($entries | Measure-Object -Property Length -Sum).Sum) / 1MB, 1) + " MB")
  $ext = $entries | Group-Object { [IO.Path]::GetExtension($_.FullName).ToLower() } | Sort-Object Count -Descending | Select-Object -First 8
  Write-Output ('TOP EXT: ' + (($ext | ForEach-Object { $(if ($_.Name) { $_.Name } else { '(none)' }) + ':' + $_.Count }) -join ' '))
  $interesting = @($names | Where-Object { $_ -match '(?i)(classes\d*\.dex|AndroidManifest\.xml|\.so$|\.dll$|\.exe$|app\.asar|package\.json|\.wasm$|libflutter|libapp\.so|assets/index\.android\.bundle|\.jar$)' } | Select-Object -First 25)
  if ($interesting.Count -gt 0) { Write-Output '--- notable entries ---'; $interesting | ForEach-Object { Write-Output ('  ' + $_) } }
  $sel = @($entries | Where-Object { $_.FullName -like $Filter })
  if ($Extract) {
    $out = [IO.Path]::GetFullPath($Extract)
    New-Item -ItemType Directory -Path $out -Force | Out-Null
    $total = [int64]0; $done = 0
    foreach ($e in $sel) {
      $dest = [IO.Path]::GetFullPath((Join-Path $out ($e.FullName -replace '/', '\')))
      if (-not $dest.StartsWith($out, [StringComparison]::OrdinalIgnoreCase)) { Write-Output ('BLOCKED path traversal: ' + $e.FullName); continue }
      $total += $e.Length
      if ($total -gt ([int64]$MaxMB * 1MB)) { Write-Output "STOPPED: extraction size cap $MaxMB MB reached"; break }
      New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
      [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true)
      $done++
    }
    Write-Output "extracted $done file(s) to $out"
  } else {
    Write-Output '--- entries ---'
    $sel | Select-Object -First $Max | ForEach-Object { Write-Output ('{0,10}  {1}' -f $_.Length, $_.FullName) }
    if ($sel.Count -gt $Max) { Write-Output "... showing $Max of $($sel.Count); use -Filter" }
  }
} finally { $zip.Dispose() }
Write-Output 'Listing is an observation of package contents; it does not show runtime behavior.'
