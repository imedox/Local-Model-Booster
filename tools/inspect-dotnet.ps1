# SYNOPSIS: List public types and members of a .NET assembly to verify an API exists (reflection, read-only)
# USAGE: bt inspect-dotnet -Assembly bin\Debug\net8.0\Foo.dll [-TypeFilter "*Window*"] [-Members] [-Max 60]
param(
  [Parameter(Mandatory = $true)][string]$Assembly,
  [string]$TypeFilter = '*',
  [switch]$Members,
  [int]$Max = 60
)
$ErrorActionPreference = 'Continue'
if (-not (Test-Path -LiteralPath $Assembly -PathType Leaf)) { Write-Output "Assembly not found: $Assembly"; exit 2 }
Write-Output 'NOTE: Windows PowerShell 5.1 loads assemblies into .NET Framework; modern .NET (net6+) assemblies may fail to load or lack dependencies. If so, use PowerShell 7+ or verify via the XML docs / source / a tiny compile test.'
try { $asm = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $Assembly).Path) } catch { Write-Output ('LOAD FAILED: ' + $_.Exception.Message); exit 3 }
try { $types = $asm.GetExportedTypes() } catch [Reflection.ReflectionTypeLoadException] { $types = @($_.Exception.Types | Where-Object { $_ -and $_.IsPublic }); Write-Output 'WARNING: some types could not be loaded (missing dependencies)' } catch { Write-Output ('TYPE ENUMERATION FAILED: ' + $_.Exception.Message); exit 3 }
$sel = @($types | Where-Object { $_.FullName -like $TypeFilter } | Sort-Object FullName)
Write-Output ("assembly: " + $asm.GetName().Name + ' ' + $asm.GetName().Version + ' | matching types: ' + $sel.Count)
$shown = 0
foreach ($t in $sel) {
  $kind = 'class'
  if ($t.IsInterface) { $kind = 'interface' } elseif ($t.IsEnum) { $kind = 'enum' } elseif ($t.IsValueType) { $kind = 'struct' }
  Write-Output ("$kind " + $t.FullName)
  if ($Members) {
    $flags = [Reflection.BindingFlags]'Public,Instance,Static,DeclaredOnly'
    try {
      foreach ($c in $t.GetConstructors()) { Write-Output ('    new(' + (($c.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', ') + ')') }
      foreach ($p in $t.GetProperties($flags)) { Write-Output ('    prop  ' + $p.PropertyType.Name + ' ' + $p.Name) }
      foreach ($m in $t.GetMethods($flags)) { if (-not $m.IsSpecialName) { Write-Output ('    method ' + $m.ReturnType.Name + ' ' + $m.Name + '(' + (($m.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', ') + ')') } }
      foreach ($e in $t.GetEvents($flags)) { Write-Output ('    event ' + $e.Name) }
    } catch { Write-Output ('    (members unavailable: ' + $_.Exception.Message + ')') }
  }
  $shown++
  if ($shown -ge $Max) { Write-Output "... stopped at $Max types"; break }
}
