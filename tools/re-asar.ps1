# SYNOPSIS: List or extract an Electron ASAR archive in pure PowerShell (zip-slip safe, size capped)
# USAGE: bt re-asar -Path app.asar -List [-Filter "*.js"] [-Max 200]   |   -Extract D:\out [-Filter "main*"] [-MaxMB 200]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [switch]$List,
  [string]$Extract = '',
  [string]$Filter = '*',
  [int]$Max = 200,
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
$f = (Resolve-Path -LiteralPath $Path).Path
$fs = [IO.File]::Open($f, 'Open', 'Read', 'ReadWrite')
try {
  $hdr = New-Object byte[] 16
  if ($fs.Read($hdr, 0, 16) -lt 16) { Write-Output 'too small for ASAR'; exit 1 }
  $pickle = [BitConverter]::ToUInt32($hdr, 4)
  $jsonLen = [BitConverter]::ToUInt32($hdr, 12)
  if ([BitConverter]::ToUInt32($hdr, 0) -ne 4 -or $jsonLen -le 0 -or $jsonLen -gt $fs.Length -or $pickle -gt $fs.Length) { Write-Output 'Not a valid ASAR header'; exit 1 }
  $jb = New-Object byte[] ([int]$jsonLen)
  $null = $fs.Read($jb, 0, [int]$jsonLen)
  $json = [Text.Encoding]::UTF8.GetString($jb)
  $dataStart = 8 + [int64]$pickle
  $tree = $null
  try {
    Add-Type -AssemblyName System.Web.Extensions
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = [int]::MaxValue; $ser.RecursionLimit = 2000
    $tree = $ser.DeserializeObject($json)
  } catch { $tree = $json | ConvertFrom-Json }
  function GetP($n, $name) { if ($n -is [System.Collections.IDictionary]) { if ($n.Contains($name)) { return $n[$name] } else { return $null } } else { return $n.$name } }
  function Kids($n) { if ($n -is [System.Collections.IDictionary]) { foreach ($k in $n.Keys) { [pscustomobject]@{ Name = $k; Value = $n[$k] } } } elseif ($n) { foreach ($p in $n.PSObject.Properties) { [pscustomobject]@{ Name = $p.Name; Value = $p.Value } } } }
  $files = New-Object System.Collections.Generic.List[object]
  function Walk($node, $prefix) {
    $fl = GetP $node 'files'
    foreach ($k in (Kids $fl)) {
      $child = $k.Value
      $rel = $(if ($prefix) { $prefix + '/' + $k.Name } else { $k.Name })
      if (GetP $child 'files') { Walk $child $rel }
      else { $files.Add([pscustomobject]@{ Path = $rel; Size = [int64](GetP $child 'size'); Offset = (GetP $child 'offset'); Unpacked = [bool](GetP $child 'unpacked') }) }
    }
  }
  Walk $tree ''
  $sel = @($files | Where-Object { $_.Path -like $Filter })
  Write-Output ("ASAR: " + $files.Count + " files, matching filter: " + $sel.Count + " | data starts at 0x" + $dataStart.ToString('X'))
  if ($Extract) {
    $out = [IO.Path]::GetFullPath($Extract)
    New-Item -ItemType Directory -Path $out -Force | Out-Null
    $total = [int64]0; $done = 0; $skipped = 0
    foreach ($e in $sel) {
      if ($e.Unpacked -or -not $e.Offset) { $skipped++; continue }
      $dest = [IO.Path]::GetFullPath((Join-Path $out ($e.Path -replace '/', '\')))
      if (-not $dest.StartsWith($out, [StringComparison]::OrdinalIgnoreCase)) { Write-Output ("BLOCKED path traversal: " + $e.Path); continue }
      $total += $e.Size
      if ($total -gt ([int64]$MaxMB * 1MB)) { Write-Output "STOPPED: extraction size cap $MaxMB MB reached"; break }
      New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
      $fs.Position = $dataStart + [int64]$e.Offset
      $data = New-Object byte[] ([int]$e.Size)
      $r = 0; while ($r -lt $data.Length) { $g = $fs.Read($data, $r, $data.Length - $r); if ($g -le 0) { break }; $r += $g }
      [IO.File]::WriteAllBytes($dest, $data)
      $done++
    }
    Write-Output "extracted: $done file(s) to $out | skipped (unpacked/external): $skipped"
  } else {
    $sel | Select-Object -First $Max | ForEach-Object { Write-Output ('{0,10}  {1}{2}' -f $_.Size, $_.Path, $(if ($_.Unpacked) { '  (unpacked)' } else { '' })) }
    if ($sel.Count -gt $Max) { Write-Output "... showing $Max of $($sel.Count); use -Filter" }
  }
} finally { $fs.Close() }
Write-Output 'Next: bt find-symbol -Path <extracted dir> -Include "*.js" -Pattern "ipcMain|contextBridge|preload"  (or REA analyze_javascript_application for the module graph)'
