$global:BiliHealth   = 'http://127.0.0.1:8787/__bili/health'
$global:BiliSessions = Join-Path $env:TEMP 'bili-sessions'

function Test-Bili {
    try { Invoke-RestMethod $global:BiliHealth -TimeoutSec 1 | Out-Null; $true } catch { $false }
}

function Start-Bili {
    if (Test-Bili) { return }
    $node = 'C:\Program Files\nodejs\node.exe'
    $bili = "$env:APPDATA\npm\node_modules\billion-context\dist\index.js"
    Start-Process -FilePath $node -ArgumentList "`"$bili`"", 'start' -WindowStyle Hidden
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-Bili) { return }
    }
    Write-Warning 'bili did not become healthy on port 8787'
}

function Stop-Bili {
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
        Where-Object { $_.CommandLine -like '*billion-context*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId }
}

function Enter-BiliSession {
    New-Item -ItemType Directory -Force -Path $global:BiliSessions | Out-Null
    Set-Content -Path (Join-Path $global:BiliSessions "$PID.txt") -Value (Get-Date)
}

function Exit-BiliSession {
    Remove-Item (Join-Path $global:BiliSessions "$PID.txt") -ErrorAction SilentlyContinue
    $alive = Get-ChildItem $global:BiliSessions -Filter *.txt -ErrorAction SilentlyContinue |
        Where-Object {
            if (Get-Process -Id ([int]$_.BaseName) -ErrorAction SilentlyContinue) { $true }
            else { Remove-Item $_.FullName -ErrorAction SilentlyContinue; $false }
        }
    if (-not $alive) { Stop-Bili }
}

function claude {
    Enter-BiliSession
    try {
        Start-Bili
        $exe = Get-Command claude -CommandType Application | Select-Object -First 1 -ExpandProperty Source
        & $exe @args
    } finally {
        Exit-BiliSession
    }
}

function bclaude {
    Enter-BiliSession
    try {
        Start-Bili
        bili claude @args
    } finally {
        Exit-BiliSession
    }
}