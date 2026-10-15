# SYNOPSIS: Scan files for likely secrets (keys, tokens, passwords, private keys); values are masked in output
# USAGE: bt secret-scan [-Path .] [-Max 50]
param([string]$Path = '.', [int]$Max = 50)
$ErrorActionPreference = 'SilentlyContinue'
$root = (Resolve-Path -LiteralPath $Path).Path
$skipRe = '\\(\.git|bin|obj|node_modules|\.venv|venv|dist|build|__pycache__|\.vs|\.idea|\.agent|packages)(\\|$)'
$binExt = @('.png', '.jpg', '.jpeg', '.gif', '.ico', '.zip', '.7z', '.gz', '.dll', '.exe', '.pdf', '.bin', '.gguf', '.woff', '.woff2', '.ttf', '.mp3', '.mp4', '.pdb', '.nupkg')
$patterns = [ordered]@{
  'AWS access key'   = 'AKIA[0-9A-Z]{16}'
  'Private key'      = '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----'
  'GitHub token'     = 'gh[pousr]_[A-Za-z0-9]{36,}'
  'API key (sk-)'    = 'sk-[A-Za-z0-9_-]{20,}'
  'Slack token'      = 'xox[baprs]-[A-Za-z0-9-]{10,}'
  'JWT'              = 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}'
  'Credential assignment' = '(?i)(password|passwd|pwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*["''][^"''\s]{6,}["'']'
  'Connection string password' = '(?i)(Password|Pwd)=[^;"''\s]{4,}'
}
if (Test-Path -LiteralPath $root -PathType Leaf) { $files = @(Get-Item -LiteralPath $root); $base = Split-Path $root -Parent } else { $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force; $base = $root }
$count = 0
foreach ($f in $files) {
  $rel = $f.FullName.Substring($base.Length)
  if ($rel -match $skipRe) { continue }
  if ($f.Name -match '^\.env') { Write-Output ('WARNING env file present: ' + $rel.TrimStart('\') + ' (make sure it is git-ignored)') }
  if ($binExt -contains $f.Extension.ToLower() -or $f.Length -gt 1MB) { continue }
  foreach ($k in $patterns.Keys) {
    foreach ($m in (Select-String -LiteralPath $f.FullName -Pattern $patterns[$k])) {
      $v = $m.Matches[0].Value
      if ($v.Length -gt 4) { $masked = $v.Substring(0, 4) + '***' } else { $masked = '***' }
      Write-Output ($rel.TrimStart('\') + ':' + $m.LineNumber + ' [' + $k + '] ' + $masked)
      $count++
      if ($count -ge $Max) { break }
    }
    if ($count -ge $Max) { break }
  }
  if ($count -ge $Max) { Write-Output "... stopped at $Max findings"; break }
}
Write-Output "potential secrets: $count"
if ($count -gt 0) { exit 1 }
