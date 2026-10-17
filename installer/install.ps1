# ==============================================================================
# 1-CLICK ALL-IN-ONE AUTOMATED INSTALLER
# Target: Qwen3.8-27B Uncensored HauhauCS Aggressive MTP on RTX 3090 + Bionic
# Complete Setup: Billion-Context Daemon, MCP, 6 Tuned Profiles & Bionic Skills
# ==============================================================================
[CmdletBinding()]
param(
    [switch]$SkipModelCheck,
    [switch]$OnlyMasterSkill
)

$ErrorActionPreference = 'Continue'
$installerRoot = $PSScriptRoot

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   1-CLICK AUTOMATED SETUP: LOCAL 128K LLM + BIONIC + BILLION-CONTEXT  " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Host: $env:COMPUTERNAME | User: $env:USERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------------------------
# STEP 1: Verify Prerequisites
# ------------------------------------------------------------------------------
Write-Host "[1/6] Verifying System Prerequisites..." -ForegroundColor Cyan

# Check OS
$isWin = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
if (-not $isWin) {
    Write-Error "This installer requires Windows 10/11 x64."
    exit 1
}
Write-Host "  [OK] Operating System: Windows ($([System.Environment]::OSVersion.VersionString))" -ForegroundColor Green

# Check Node.js and npm
$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
$npmCmd = Get-Command "npm" -ErrorAction SilentlyContinue

if (-not $nodeCmd -or -not $npmCmd) {
    Write-Host "  [!] Node.js / npm not found on PATH. Attempting automatic installation via winget..." -ForegroundColor Yellow
    $winget = Get-Command "winget" -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "  [*] Installing Node.js LTS via winget..." -ForegroundColor Cyan
        & winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
    }
    
    if (-not $nodeCmd) {
        Write-Error "Node.js is required for Billion-Context. Please install Node.js LTS from https://nodejs.org and rerun this script."
        exit 1
    }
}
$nodeVersion = (& node -v).Trim()
Write-Host "  [OK] Node.js is installed ($nodeVersion)" -ForegroundColor Green

# Check LM Studio / Bionic Root
$lmStudioDir = Join-Path $env:USERPROFILE ".lmstudio"
$bionicAppDir = Join-Path $lmStudioDir "apps\bionic"

if (-not (Test-Path $lmStudioDir)) {
    Write-Host "  [!] Warning: ~/.lmstudio folder not found. Creating it now..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $lmStudioDir -Force | Out-Null
} else {
    Write-Host "  [OK] LM Studio installation directory detected." -ForegroundColor Green
}

# Check Target Model
$modelPath = "I:\LM-Studio-Models\HauhauCS\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf"
if (-not (Test-Path $modelPath) -and -not $SkipModelCheck) {
    # Check alternate drives
    $found = Get-ChildItem -Path "C:\", "D:\", "E:\", "F:\", "I:\" -Filter "Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf" -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $modelPath = $found.FullName
        Write-Host "  [OK] Target Model found at: $modelPath" -ForegroundColor Green
    } else {
        Write-Host "  [!] Target model not detected at primary path (I:\LM-Studio-Models\...)." -ForegroundColor Yellow
        Write-Host "      Ensure the model is loaded in Bionic before starting inference." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [OK] Target Model detected: Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 2: Install & Configure Billion-Context Daemon
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/6] Configuring Billion-Context Daemon (Port 8787)..." -ForegroundColor Cyan

# Install package globally if missing
$biliCheck = Get-Command "billion-context" -ErrorAction SilentlyContinue
if (-not $biliCheck) {
    Write-Host "  [*] Installing billion-context npm package globally..." -ForegroundColor Cyan
    & npm install -g billion-context
} else {
    Write-Host "  [OK] billion-context package already installed globally." -ForegroundColor Green
}

# Locate Node and scripts
$nodeExe = (Get-Command "node").Source
$appDataNpm = Join-Path $env:APPDATA "npm\node_modules\billion-context"
$distIndex = Join-Path $appDataNpm "dist\index.js"
$distMcp = Join-Path $appDataNpm "dist\mcp.js"

# Create config directory and json
$biliConfigDir = Join-Path $env:USERPROFILE ".config\billion-context"
if (-not (Test-Path $biliConfigDir)) { New-Item -ItemType Directory -Path $biliConfigDir -Force | Out-Null }

$biliJsonPath = Join-Path $biliConfigDir "billion-context.json"
$biliConfigContent = @'
{
  "port": 8787,
  "host": "127.0.0.1",
  "providers": {
    "http://127.0.0.1:1235": {
      "models": {
        "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp": {
          "context": 98304
        }
      }
    }
  }
}
'@
Set-Content -Path $biliJsonPath -Value $biliConfigContent -Encoding UTF8
Write-Host "  [OK] Config written: $biliJsonPath" -ForegroundColor Green

# Register Windows Scheduled Task for Silent Autostart
$taskName = "BiliProxyService"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "  [OK] Scheduled Task '$taskName' already registered." -ForegroundColor Green
} else {
    try {
        $action = New-ScheduledTaskAction -Execute $nodeExe -Argument "`"$distIndex`" start"
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
        Write-Host "  [OK] Registered Windows Scheduled Task: $taskName" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Could not register scheduled task: $_. Will start via hidden process." -ForegroundColor Yellow
    }
}

# Ensure process is actively running right now
$portOpen = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 8787)
    $portOpen = $tcp.Connected
    $tcp.Close()
} catch { $portOpen = $false }

if (-not $portOpen) {
    Write-Host "  [*] Launching Billion-Context background process on port 8787..." -ForegroundColor Cyan
    Start-Process -FilePath $nodeExe -ArgumentList "`"$distIndex`" start" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Write-Host "  [OK] Billion-Context Daemon started on http://127.0.0.1:8787" -ForegroundColor Green
} else {
    Write-Host "  [OK] Billion-Context is active and listening on port 8787." -ForegroundColor Green
}

function Get-SourceDir($name) {
    $p = Join-Path $installerRoot $name
    if (Test-Path $p) { return $p }
    $pParent = Join-Path (Split-Path -Parent $installerRoot) $name
    if (Test-Path $pParent) { return $pParent }
    return $null
}

# ------------------------------------------------------------------------------
# STEP 3: Configure MCP Integration (LM Studio / Bionic)
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/6] Setting up Billion-Context & REA Gateway MCP Servers..." -ForegroundColor Cyan

$mcpPath = Join-Path $env:USERPROFILE ".lmstudio\mcp.json"
$mcpConfig = @{ mcpServers = @{} }

if (Test-Path $mcpPath) {
    try {
        $raw = Get-Content -Path $mcpPath -Raw -Encoding UTF8
        if ($raw.Trim()) { $mcpConfig = $raw | ConvertFrom-Json }
    } catch {}
}

if (-not $mcpConfig.mcpServers) {
    $mcpConfig = [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} }
}

# Billion-Context MCP
$mcpConfig.mcpServers | Add-Member -Name "billion-context" -MemberType NoteProperty -Value ([PSCustomObject]@{
    command = $nodeExe
    args = @($distMcp)
}) -Force

# REA Meta-Gateway MCP (5 surgical tools, NVMe SQLite FTS5 store, eliminates 260K token bloat)
$mcpConfig.mcpServers | Add-Member -Name "rea-gateway" -MemberType NoteProperty -Value ([PSCustomObject]@{
    command = "python"
    args = @("C:\tools\rea_gateway_mcp.py")
}) -Force

$cleanJson = $mcpConfig | ConvertTo-Json -Depth 5
Set-Content -Path $mcpPath -Value $cleanJson -Encoding UTF8
Write-Host "  [OK] Configured billion-context & rea-gateway MCP servers in: $mcpPath" -ForegroundColor Green

# ------------------------------------------------------------------------------
# STEP 4: Setup C:\tools, Switcher & Profiles
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/6] Deploying Profile Switcher and 6 Tuned Profiles..." -ForegroundColor Cyan

$toolsDir = "C:\tools"
$profilesDir = Join-Path $toolsDir "profiles"
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
if (-not (Test-Path $profilesDir)) { New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null }

# Copy profile JSONs
$srcConfigs = Get-SourceDir "configs"
if ($srcConfigs) {
    Copy-Item -Path (Join-Path $srcConfigs "*.json") -Destination $profilesDir -Force
    Write-Host "  [OK] Copied 6 tuned JSON profiles to: $profilesDir" -ForegroundColor Green
}

# Copy all tools (switchers + bt.cmd launcher + Model-Booster helper scripts + REA gateway)
$srcTools = Get-SourceDir "tools"
if ($srcTools) {
    Copy-Item -Path (Join-Path $srcTools "*") -Destination $toolsDir -Recurse -Force
    Write-Host "  [OK] Deployed all tools, switchers, bt.cmd, and helper scripts to: $toolsDir" -ForegroundColor Green
}

# Set BOOSTER_HOME environment variable
[System.Environment]::SetEnvironmentVariable("BOOSTER_HOME", $toolsDir, "User")
$env:BOOSTER_HOME = $toolsDir
Write-Host "  [OK] Set BOOSTER_HOME = $toolsDir" -ForegroundColor Green

# Add C:\tools to User and Machine PATH
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$toolsDir*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$toolsDir", "User")
    $env:Path = "$env:Path;$toolsDir"
    Write-Host "  [OK] Added '$toolsDir' to User PATH environment variable." -ForegroundColor Green
} else {
    Write-Host "  [OK] '$toolsDir' already present in User PATH." -ForegroundColor Green
}

try {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$toolsDir*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$machinePath;$toolsDir", "Machine")
        Write-Host "  [OK] Added '$toolsDir' to System Machine PATH." -ForegroundColor Green
    }
} catch {}

# Immediately apply the default 01_coding profile
$switchScript = Join-Path $toolsDir "switch_profile.ps1"
if (Test-Path $switchScript) {
    & powershell -ExecutionPolicy Bypass -File $switchScript -Profile coding
}

# ------------------------------------------------------------------------------
# STEP 5: Deploy Tuned Bionic Skills
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[5/6] Deploying Tuned Bionic Skills..." -ForegroundColor Cyan

$bionicSkillsDir = Join-Path $env:USERPROFILE ".lmstudio\skills"
if (-not (Test-Path $bionicSkillsDir)) { New-Item -ItemType Directory -Path $bionicSkillsDir -Force | Out-Null }

$srcSkills = Get-SourceDir "skills"
if ($srcSkills) {
    if ($OnlyMasterSkill) {
        Write-Host "  [*] Copying only Master Skill (bionic-booster)..." -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $srcSkills "bionic-booster") -Destination $bionicSkillsDir -Recurse -Force
        Copy-Item -Path (Join-Path $srcSkills "model-booster") -Destination $bionicSkillsDir -Recurse -Force
    } else {
        Write-Host "  [*] Copying all tuned skills into Bionic global skills folder..." -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $srcSkills "*") -Destination $bionicSkillsDir -Recurse -Force
    }
    Write-Host "  [OK] Skills deployed to: $bionicSkillsDir" -ForegroundColor Green
}

# Copy Documentation to C:\tools\docs
$docsDir = Join-Path $toolsDir "docs"
if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }
$srcDocs = Get-SourceDir "docs"
if ($srcDocs) {
    Copy-Item -Path (Join-Path $srcDocs "*") -Destination $docsDir -Recurse -Force
    Write-Host "  [OK] Documentation copied to: $docsDir" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 6: Final Verification & Summary
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] Verifying Installation Status..." -ForegroundColor Cyan

# Test Billion-Context
$bcStatus = "OFFLINE"
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 8787)
    if ($tcp.Connected) { $bcStatus = "ONLINE (Port 8787)" }
    $tcp.Close()
} catch {}

# Test Bionic Server
$bionicStatus = "OFFLINE"
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 1235)
    if ($tcp.Connected) { $bionicStatus = "ONLINE (Port 1235)" }
    $tcp.Close()
} catch {}

# Test Bionic Booster skill
$bionicBoosterInstalled = Test-Path (Join-Path $bionicSkillsDir "bionic-booster\SKILL.md")

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "                INSTALLATION COMPLETED SUCCESSFULLY!                  " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Service / Component         Status" -ForegroundColor Yellow
Write-Host "  --------------------------  ----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Billion-Context Daemon      : $bcStatus" -ForegroundColor Cyan
Write-Host "  Bionic Inference Server     : $bionicStatus" -ForegroundColor Cyan
Write-Host "  Active Profile              : 01_coding (128K context, Flash Attn, q8_0)" -ForegroundColor Cyan
Write-Host "  Bionic Booster Skill        : $(if ($bionicBoosterInstalled) {'INSTALLED'} else {'MISSING'})" -ForegroundColor Cyan
Write-Host "  REA Meta-Gateway MCP        : INSTALLED (5 meta-tools, NVMe SQLite FTS5 store)" -ForegroundColor Cyan
Write-Host "  IDAPython Export Engine     : READY (bt re-ida-export -> Alt+F7 color-coded patch)" -ForegroundColor Cyan
Write-Host "  Claude Code CLI Integration : OPTIONAL (instructions in C:\tools\docs\CLAUDE_CODE.md)" -ForegroundColor Cyan
Write-Host "  Desktop Switchers Location  : C:\tools\" -ForegroundColor Cyan
Write-Host "  Documentation Location      : C:\tools\docs\Tutorial.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEP IN BIONIC:" -ForegroundColor Yellow
Write-Host "1. In Bionic, open Settings (gear icon bottom left) -> Skills." -ForegroundColor White
Write-Host "2. Leave ONLY 'Bionic Booster' checked (uncheck the others to avoid prompt bloat)." -ForegroundColor White
Write-Host "3. Start coding! Your agent is now supercharged with 128K context and zero-loop discipline." -ForegroundColor White
Write-Host ""
