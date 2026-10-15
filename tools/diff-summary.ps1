# SYNOPSIS: Summarize the working-tree diff: stat, file status, whitespace problems, untracked files, size warning
# USAGE: bt diff-summary
$ErrorActionPreference = 'SilentlyContinue'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Output 'git not found'; exit 2 }
if (((& git rev-parse --is-inside-work-tree 2>&1) -join '') -ne 'true') { Write-Output 'Not a git repository'; exit 2 }
Write-Output '== name-status =='
& git diff --name-status
& git diff --cached --name-status
Write-Output '== stat =='
& git diff --stat
Write-Output '== whitespace check =='
$chk = @(& git diff --check 2>&1)
if ($chk.Count -eq 0) { Write-Output 'clean' } else { $chk | Select-Object -First 20 }
Write-Output '== untracked (not ignored) =='
& git ls-files --others --exclude-standard | Select-Object -First 30
$sum = 0
foreach ($n in (& git diff --numstat)) { $p = "$n" -split "`t"; if ($p.Count -ge 2 -and $p[0] -match '^\d+$') { $sum += [int]$p[0] + [int]$p[1] } }
Write-Output "changed lines (added+removed, unstaged): $sum"
if ($sum -gt 500) { Write-Output 'WARNING: large diff. Check for accidental rewrites or line-ending changes (bt line-endings).' }
