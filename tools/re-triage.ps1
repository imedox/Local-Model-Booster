# SYNOPSIS: Offline triage of a file (no IDA, no REA): type, hashes, PE headers, sections+entropy, imports, .NET/signature flags
# USAGE: bt re-triage -Path C:\x\app.exe [-MaxImports 60]
param([Parameter(Mandatory = $true)][string]$Path, [int]$MaxImports = 60)
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
$item = Get-Item -LiteralPath $f
Write-Output ("FILE   : " + $f)
Write-Output ("SIZE   : " + $item.Length + " bytes")
Write-Output ("SHA256 : " + (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash)
$fs = [IO.File]::Open($f, 'Open', 'Read', 'ReadWrite')
$br = New-Object IO.BinaryReader($fs)
try {
  $head = $br.ReadBytes(16)
  $type = 'unknown'
  if ($head.Length -ge 2 -and $head[0] -eq 0x4D -and $head[1] -eq 0x5A) { $type = 'PE (MZ)' }
  elseif ($head.Length -ge 4 -and $head[0] -eq 0x7F -and $head[1] -eq 0x45 -and $head[2] -eq 0x4C -and $head[3] -eq 0x46) { $type = 'ELF' }
  elseif ($head.Length -ge 4 -and $head[0] -eq 0x50 -and $head[1] -eq 0x4B -and $head[2] -eq 3 -and $head[3] -eq 4) { $type = 'ZIP container (APK/JAR/MSIX/DOCX/...)' }
  elseif ($head.Length -ge 4 -and $head[0] -eq 0 -and $head[1] -eq 0x61 -and $head[2] -eq 0x73 -and $head[3] -eq 0x6D) { $type = 'WebAssembly' }
  elseif ($head.Length -ge 4 -and (($head[0] -eq 0xCF -and $head[1] -eq 0xFA) -or ($head[0] -eq 0xCA -and $head[1] -eq 0xFE -and $head[2] -eq 0xBA) -or ($head[0] -eq 0xFE -and $head[1] -eq 0xED))) { $type = 'Mach-O' }
  elseif ($head.Length -ge 4 -and $head[0] -eq 4 -and $head[1] -eq 0 -and $head[2] -eq 0 -and $head[3] -eq 0 -and $item.Extension -eq '.asar') { $type = 'ASAR archive (Electron)' }
  elseif ([Text.Encoding]::ASCII.GetString($head) -like 'SQLite format 3*') { $type = 'SQLite database' }
  Write-Output ("TYPE   : " + $type)
  if ($type -like 'PE*') {
    $vi = $item.VersionInfo
    if ($vi) { Write-Output ("VERSION: Company=[" + $vi.CompanyName + "] Product=[" + $vi.ProductName + "] FileVersion=[" + $vi.FileVersion + "] OriginalFilename=[" + $vi.OriginalFilename + "]") }
    $fs.Position = 0x3C
    $peOff = $br.ReadInt32()
    $fs.Position = $peOff
    if ($br.ReadUInt32() -ne 0x00004550) { Write-Output 'PE signature missing (corrupt or not PE)'; exit 1 }
    $machine = $br.ReadUInt16(); $nsec = $br.ReadUInt16(); $ts = $br.ReadUInt32()
    $null = $br.ReadUInt32(); $null = $br.ReadUInt32()
    $sizeOpt = $br.ReadUInt16(); $chars = $br.ReadUInt16()
    $optStart = $fs.Position
    $magic = $br.ReadUInt16()
    $is64 = ($magic -eq 0x20B)
    $mname = switch ($machine) { 0x14C { 'x86' } 0x8664 { 'x64' } 0xAA64 { 'ARM64' } 0x1C4 { 'ARMNT' } default { ('0x{0:X}' -f $machine) } }
    $fs.Position = $optStart + 16; $entry = $br.ReadUInt32()
    $fs.Position = $optStart + 68; $subsys = $br.ReadUInt16(); $dllc = $br.ReadUInt16()
    $when = [DateTimeOffset]::FromUnixTimeSeconds([int64]$ts).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')
    $kind = 'EXE'; if ($chars -band 0x2000) { $kind = 'DLL' }
    Write-Output ("PE     : " + $mname + " " + $(if ($is64) { 'PE32+' } else { 'PE32' }) + " " + $kind + " subsystem=" + $subsys + " entryRVA=0x" + $entry.ToString('X') + " linkerTimestamp(UTC)=" + $when + " (can be forged)")
    Write-Output ("HARDEN : ASLR=" + [bool]($dllc -band 0x40) + " DEP/NX=" + [bool]($dllc -band 0x100) + " CFG=" + [bool]($dllc -band 0x4000) + " HighEntropyVA=" + [bool]($dllc -band 0x20))
    if ($is64) { $dirBase = $optStart + 112 } else { $dirBase = $optStart + 96 }
    $dirs = @()
    for ($i = 0; $i -lt 16; $i++) { $fs.Position = $dirBase + 8 * $i; $r = $br.ReadUInt32(); $s = $br.ReadUInt32(); $dirs += , @($r, $s) }
    $secStart = $optStart + $sizeOpt
    $secs = @()
    for ($i = 0; $i -lt $nsec; $i++) {
      $fs.Position = $secStart + 40 * $i
      $nm = ([Text.Encoding]::ASCII.GetString($br.ReadBytes(8))).TrimEnd([char]0)
      $vs = $br.ReadUInt32(); $va = $br.ReadUInt32(); $rs = $br.ReadUInt32(); $rp = $br.ReadUInt32()
      $null = $br.ReadBytes(12); $sc = $br.ReadUInt32()
      $secs += [pscustomobject]@{ Name = $nm; VA = $va; VSize = $vs; RawPtr = $rp; RawSize = $rs; Chars = $sc }
    }
    function RvaToOff([uint32]$rva) {
      foreach ($s in $secs) { $span = [Math]::Max($s.VSize, $s.RawSize); if ($rva -ge $s.VA -and $rva -lt ($s.VA + $span)) { return [int64]($rva - $s.VA + $s.RawPtr) } }
      return -1
    }
    Write-Output '--- sections (entropy of first 512 KB; > 7.2 suggests packed/encrypted) ---'
    $packed = $false
    foreach ($s in $secs) {
      $ent = 0.0
      if ($s.RawSize -gt 0 -and $s.RawPtr -lt $fs.Length) {
        $fs.Position = $s.RawPtr
        $n = [int][Math]::Min([Math]::Min($s.RawSize, 524288), $fs.Length - $s.RawPtr)
        $buf = $br.ReadBytes($n)
        if ($buf.Length -gt 0) {
          $cnt = New-Object 'int[]' 256
          foreach ($b in $buf) { $cnt[$b]++ }
          foreach ($c in $cnt) { if ($c -gt 0) { $p = $c / [double]$buf.Length; $ent -= $p * [Math]::Log($p, 2) } }
        }
      }
      $flag = ''
      if ($ent -gt 7.2) { $flag = '  <-- high entropy'; $packed = $true }
      if ($s.Name -match '^(UPX|\.themida|\.vmp|\.aspack|\.petite|\.enigma)') { $flag += '  <-- packer-like name'; $packed = $true }
      $x = ''; if ($s.Chars -band 0x20000000) { $x = 'X' }; if ($s.Chars -band 0x80000000) { $x += 'W' }
      Write-Output ('{0,-9} VA=0x{1:X8} VSize=0x{2:X} Raw=0x{3:X}/{4} entropy={5:N2} {6}{7}' -f $s.Name, $s.VA, $s.VSize, $s.RawPtr, $s.RawSize, $ent, $x, $flag)
    }
    if ($packed) { Write-Output 'NOTE: packing/obfuscation indicators present. Static results may be incomplete; do not claim the full behavior was observed.' }
    if ($dirs[14][0] -ne 0) { Write-Output 'MANAGED: CLR header present -> .NET assembly. Use REA inspect_managed_artifact or: bt inspect-dotnet -Assembly <file> -Members' }
    if ($dirs[4][0] -ne 0) {
      $sig = 'present (not verified by this tool)'
      if (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue) { $sg = Get-AuthenticodeSignature -LiteralPath $f; $sig = [string]$sg.Status + ' signer=' + $(if ($sg.SignerCertificate) { $sg.SignerCertificate.Subject } else { 'none' }) }
      Write-Output ("SIGNATURE: " + $sig)
    } else { Write-Output 'SIGNATURE: none' }
    $impRva = $dirs[1][0]
    if ($impRva -ne 0) {
      Write-Output '--- imports (DLL: first functions) ---'
      $io = RvaToOff $impRva
      $listed = 0
      if ($io -ge 0) {
        $d = 0
        while ($d -lt 200) {
          $fs.Position = $io + 20 * $d
          $oft = $br.ReadUInt32(); $null = $br.ReadUInt32(); $null = $br.ReadUInt32(); $nameRva = $br.ReadUInt32(); $ft = $br.ReadUInt32()
          if ($nameRva -eq 0 -and $ft -eq 0) { break }
          $no = RvaToOff $nameRva
          $dll = '?'
          if ($no -ge 0) { $fs.Position = $no; $bytes = New-Object System.Collections.Generic.List[byte]; for ($k = 0; $k -lt 128; $k++) { $c = $br.ReadByte(); if ($c -eq 0) { break }; $bytes.Add($c) }; $dll = [Text.Encoding]::ASCII.GetString($bytes.ToArray()) }
          $names = @()
          $thunk = $oft; if ($thunk -eq 0) { $thunk = $ft }
          $to = RvaToOff $thunk
          if ($to -ge 0) {
            $step = 4; if ($is64) { $step = 8 }
            for ($t = 0; $t -lt 400; $t++) {
              $fs.Position = $to + $step * $t
              if ($is64) { $val = $br.ReadUInt64() } else { $val = [uint64]$br.ReadUInt32() }
              if ($val -eq 0) { break }
              $ordFlag = 0x80000000; if ($is64) { $ordFlag = 0x8000000000000000 }
              if (($val -band $ordFlag) -ne 0) { $names += ('#' + ($val -band 0xFFFF)); continue }
              $ho = RvaToOff ([uint32]$val)
              if ($ho -ge 0) { $fs.Position = $ho + 2; $nb = New-Object System.Collections.Generic.List[byte]; for ($k = 0; $k -lt 128; $k++) { $c = $br.ReadByte(); if ($c -eq 0) { break }; $nb.Add($c) }; $names += [Text.Encoding]::ASCII.GetString($nb.ToArray()) }
            }
          }
          $show = @($names | Select-Object -First 8)
          Write-Output ('{0}: {1} functions  e.g. {2}' -f $dll, $names.Count, ($show -join ', '))
          $listed += $names.Count
          if ($listed -ge $MaxImports * 10) { Write-Output '... import listing capped'; break }
          $d++
        }
      }
    } else { Write-Output 'IMPORTS: none (or packed/delay-loaded)' }
  }
  elseif ($type -eq 'ELF') {
    $cls = 'ELF32'; if ($head[4] -eq 2) { $cls = 'ELF64' }
    $endian = 'little-endian'; if ($head[5] -eq 2) { $endian = 'big-endian' }
    $fs.Position = 18; $em = $br.ReadUInt16()
    $arch = switch ($em) { 0x3E { 'x86-64' } 0x03 { 'x86' } 0xB7 { 'AArch64' } 0x28 { 'ARM' } 0xF3 { 'RISC-V' } default { ('0x{0:X}' -f $em) } }
    Write-Output ("ELF    : " + $cls + " " + $endian + " machine=" + $arch)
    Write-Output 'NEXT   : section/symbol detail needs REA (objdump/Rizin/pwntools provider) or Ghidra/IDA.'
  }
  elseif ($type -like 'ZIP*') { Write-Output 'NEXT   : bt re-archive -Path <file>   (lists entries, flags APK/MSIX/JAR/Electron)' }
  elseif ($type -like 'ASAR*') { Write-Output 'NEXT   : bt re-asar -Path <file> -List' }
  else { Write-Output 'NEXT   : bt re-strings -Path <file> -Preset url' }
} finally { $br.Close(); $fs.Close() }
Write-Output ''
Write-Output ('MODE   : ' + $reMode + '. This was static triage only: nothing was executed, so no runtime behavior is established.')
if ($reMode -eq 'with-ida') { Write-Output 'NEXT   : decompile with the user''s IDA via REA: bt rea-run -Command function -Target <file> -Name <func> -Provider ida' }
else { Write-Output 'NEXT   : deeper native analysis needs Ghidra/Hopper through REA (bt rea-doctor -Provider ghidra), or stay with strings/imports evidence.' }
