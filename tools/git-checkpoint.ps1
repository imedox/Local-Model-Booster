# SYNOPSIS: Safe git helper: status, branch agent/<name>, commit specific files, diff, log, restore (needs -Yes)
# USAGE: bt git-checkpoint -Action status|branch|commit|diff|log|restore [-Name task] [-Message "fix: x"] [-Files "a.cs,b.cs"] [-Yes]
param(
  [ValidateSet('status', 'branch', 'commit', 'diff', 'log', 'restore')][string]$Action = 'status',
  [string]$Name = '',
  [string]$Message = '',
  [string[]]$Files,
  [switch]$Yes
)
$ErrorActionPreference = 'Continue'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Output 'git not found'; exit 2 }
$inside = (& git rev-parse --is-inside-work-tree 2>&1) -join ''
if ($inside -ne 'true') { Write-Output 'Not a git repository. Use "bt backup-files" before editing instead.'; exit 2 }
$list = @($Files | ForEach-Object { $_ -split '[,;]' } | Where-Object { $_ } | ForEach-Object { $_.Trim() })
switch ($Action) {
  'status' { & git status --short -b }
  'log' { & git log --oneline -n 15 }
  'diff' { Write-Output '-- unstaged --'; & git diff --stat; Write-Output '-- staged --'; & git diff --cached --stat }
  'branch' {
    if (-not $Name) { Write-Output 'need -Name'; exit 3 }
    $safe = ($Name -replace '[^A-Za-z0-9._-]', '-')
    & git switch -c "agent/$safe"
  }
  'commit' {
    if ($list.Count -eq 0 -or -not $Message) { Write-Output 'need -Files and -Message'; exit 3 }
    foreach ($f in $list) {
      if ($f -in @('.', '*', ':/', '-A', '--all')) { Write-Output "REFUSED: broad path '$f'. List files explicitly."; exit 3 }
      if ($f -match '(^|[\\/])\.env|\.pfx$|\.key$|\.pem$|id_rsa') { Write-Output "REFUSED: '$f' looks like a secret file."; exit 3 }
    }
    & git add -- @list
    & git commit -m $Message
  }
  'restore' {
    if ($list.Count -eq 0) { Write-Output 'need -Files'; exit 3 }
    if (-not $Yes) {
      Write-Output 'This discards uncommitted changes in these files:'
      & git diff --stat -- @list
      Write-Output 'Confirm that they contain only your own changes, then rerun with -Yes.'
      exit 2
    }
    & git restore -- @list
    Write-Output 'restored'
  }
}
