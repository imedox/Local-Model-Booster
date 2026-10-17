param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("coding", "general_operation", "tool_use", "long_tasks", "max_intelligence", "max_speed")]
    [string]$Profile
)

$profileMap = @{
    "coding"             = "01_coding.json"
    "general_operation"  = "02_general_operation.json"
    "tool_use"           = "03_tool_use.json"
    "long_tasks"         = "04_long_tasks.json"
    "max_intelligence"   = "05_max_intelligence.json"
    "max_speed"          = "06_max_speed.json"
}

$candidatePaths = @(
    (Join-Path $PSScriptRoot "profiles\$($profileMap[$Profile])"),
    (Join-Path "C:\tools\profiles" $profileMap[$Profile]),
    (Join-Path $PSScriptRoot "..\configs\$($profileMap[$Profile])"),
    (Join-Path "$env:USERPROFILE\.gemini\antigravity-ide\scratch\target_tuning\configs" $profileMap[$Profile])
)

$src = $null
foreach ($p in $candidatePaths) {
    if (Test-Path $p) {
        $src = $p
        break
    }
}

if (-not $src) {
    Write-Error "Config file for [$Profile] was not found in any search path."
    exit 1
}

$bionicTargetDir = Join-Path $env:USERPROFILE ".lmstudio\apps\bionic\.internal\user-concrete-model-default-config\HauhauCS\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF"
$lmstudioTargetDir = Join-Path $env:USERPROFILE ".lmstudio\.internal\user-concrete-model-default-config\HauhauCS\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF"

if (-not (Test-Path $bionicTargetDir)) { New-Item -ItemType Directory -Path $bionicTargetDir -Force | Out-Null }
if (-not (Test-Path $lmstudioTargetDir)) { New-Item -ItemType Directory -Path $lmstudioTargetDir -Force | Out-Null }

$bionicTarget = Join-Path $bionicTargetDir "Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf.json"
$lmstudioTarget = Join-Path $lmstudioTargetDir "Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf.json"

Copy-Item -Path $src -Destination $bionicTarget -Force
Copy-Item -Path $src -Destination $lmstudioTarget -Force

(Get-Item $bionicTarget).LastWriteTime = Get-Date
(Get-Item $lmstudioTarget).LastWriteTime = Get-Date

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "[OK] Successfully switched profile to: [$Profile]" -ForegroundColor Green
Write-Host "Source: $src" -ForegroundColor DarkGray
Write-Host "Active in Bionic & LM Studio runtime config." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
