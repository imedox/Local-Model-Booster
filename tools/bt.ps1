# SYNOPSIS: Model-Booster tool launcher and dispatcher for PowerShell
# USAGE: bt <tool> <args>   |   bt list   |   bt help <tool>
$tool = $args[0]
$dir = $PSScriptRoot

if (-not $tool -or $tool -ieq 'list') {
    Write-Output 'Model-Booster tools  (run: bt <tool> <args>   |   bt help <tool>)'
    Get-ChildItem -LiteralPath $dir -Filter *.ps1 | Where-Object { $_.Name -notin 'bt.ps1', 'install.ps1', 'test_disp.ps1' } | Sort-Object Name | ForEach-Object {
        $syn = ''
        $line = Get-Content -LiteralPath $_.FullName -TotalCount 2 | Where-Object { $_ -match '^#\s*SYNOPSIS:' } | Select-Object -First 1
        if ($line) { $syn = ($line -replace '^#\s*SYNOPSIS:\s*', '') }
        Write-Output ('  {0,-16} {1}' -f $_.BaseName, $syn)
    }
    exit 0
}

if ($tool -ieq 'help') {
    $target = $args[1]
    if (-not $target) {
        Write-Output 'Usage: bt help <tool>   (run: bt list to see available tools)'
        exit 0
    }
    $f = Join-Path $dir ($target + '.ps1')
    if (-not (Test-Path -LiteralPath $f)) { Write-Output "unknown tool: $target (run: bt list)"; exit 2 }
    Get-Content -LiteralPath $f -TotalCount 4 | Where-Object { $_ -match '^#' } | ForEach-Object { Write-Output ($_ -replace '^#\s?', '') }
    exit 0
}

if ($tool -match '[\\/:\.]') {
    Write-Output "invalid tool name: $tool"
    exit 2
}

$script = Join-Path $dir ($tool + '.ps1')
if (-not (Test-Path -LiteralPath $script)) {
    Write-Output "unknown tool: $tool   (run: bt list)"
    exit 2
}

$rest = @()
if ($args.Count -gt 1) {
    $rest = $args[1..($args.Count - 1)]
}

powershell -NoProfile -ExecutionPolicy Bypass -File $script @rest
exit $LASTEXITCODE
