# SYNOPSIS: Add one dated fact to .agent\MEMORY.md under a section (dedupes, warns above 60 lines)
# USAGE: bt memory-add -Section Pitfalls -Text "symptom -> cause -> fix"
param(
  [Parameter(Mandatory = $true)][ValidateSet('Commands', 'Environment', 'Architecture', 'Pitfalls', 'Preferences')][string]$Section,
  [Parameter(Mandatory = $true)][string]$Text,
  [string]$Path = '.'
)
$ErrorActionPreference = 'Stop'
$file = Join-Path (Join-Path (Resolve-Path -LiteralPath $Path).Path '.agent') 'MEMORY.md'
if (-not (Test-Path -LiteralPath $file)) { Write-Output 'MEMORY.md missing: run "bt agent-init" first'; exit 2 }
if ($Text -match '(?i)(password|passwd|secret|token|api[_-]?key)\s*[:=]') { Write-Output 'REFUSED: text looks like a secret. Never store secrets in memory.'; exit 3 }
$lines = New-Object System.Collections.Generic.List[string]
foreach ($l in (Get-Content -LiteralPath $file)) { $lines.Add($l) }
$entry = '- ' + $Text.Trim()
if ($Section -eq 'Pitfalls' -and $entry -notmatch 'verified') { $entry += ' (verified ' + (Get-Date -Format 'yyyy-MM-dd') + ')' }
if ($lines -contains $entry) { Write-Output 'duplicate, not added'; exit 0 }
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('^##\s+' + $Section + '\s*$')) { $start = $i; break } }
if ($start -lt 0) { $lines.Add(''); $lines.Add("## $Section"); $lines.Add($entry) }
else {
  $end = $lines.Count
  for ($j = $start + 1; $j -lt $lines.Count; $j++) { if ($lines[$j] -match '^##\s') { $end = $j; break } }
  $ins = $end
  while ($ins -gt $start + 1 -and [string]::IsNullOrWhiteSpace($lines[$ins - 1])) { $ins-- }
  if ($ins -gt $start + 1 -and $lines[$ins - 1] -match '^-\s*$') { $lines[$ins - 1] = $entry } else { $lines.Insert($ins, $entry) }
}
Set-Content -LiteralPath $file -Value $lines -Encoding UTF8
Write-Output "added to $Section. total lines: $($lines.Count)"
if ($lines.Count -gt 60) { Write-Output 'WARNING: MEMORY.md exceeds 60 lines. Merge or prune stale entries.' }
