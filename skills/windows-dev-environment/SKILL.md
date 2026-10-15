---
name: windows-dev-environment
display-name: Windows Dev Environment
description: Operate cleanly on Windows with PowerShell, .NET, Python, and Node. Handles path quoting, CRLF line endings, UTF-8 encodings, and GPU sharing.
---

# Windows Dev Environment

## Shell facts

- Default shell is PowerShell, not bash. Do not use `rm -rf`, `export`, `&&` (PowerShell 5.1), or `$(...)` bash idioms.
- Chain commands with `;` or run separate calls. In PowerShell 7+, `&&` works.
- Quote paths with spaces: `"C:\My Folder\file.txt"`. Use `-LiteralPath` when brackets appear in names.
- Check availability first: `Get-Command dotnet, python, py, node, git, rg -ErrorAction SilentlyContinue`.
- Use `$env:VAR` for environment variables.

## Command equivalents

| Need | PowerShell |
|---|---|
| list | `Get-ChildItem -Force` |
| read part | `Get-Content file -TotalCount 80` / `-Tail 80` |
| search | `Select-String -Path *.cs -Pattern "x" -Recurse` or `rg -n "x"` |
| exists | `Test-Path path` |
| delete (dangerous) | `Remove-Item -LiteralPath p` after confirming the exact path |
| env check | `$PSVersionTable.PSVersion` |

## Files

- Detect line endings before editing; keep CRLF files CRLF. Do not let tools convert whole files.
- Preserve UTF-8 with or without BOM as found. Avoid `>` redirection for code (PowerShell 5.1 writes UTF-16); use `Set-Content -Encoding utf8` or an edit tool.
- Paths may exceed 260 chars; prefer short working directories.

## Toolchains

- .NET: `dotnet --info`, `dotnet build -v minimal`, `dotnet test --no-build`. Check `TargetFramework` in the csproj. Avalonia/WPF/WinForms UI code runs on the UI thread; marshal background work properly.
- Python: use `py -3 -m venv .venv` then `.\.venv\Scripts\python.exe -m pip install ...`. Never install into the system interpreter without need.
- Node: check `node -v` and the lockfile type (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`) before installing.
- Execution policy errors: do not weaken system policy; use `-ExecutionPolicy Bypass` only for a single user-approved script run.

## Node, npx and MCP on Windows

- npm/npx are `.cmd` shims: stdio MCP hosts need `cmd.exe /d /c npx -y <package> ...`. `bt rea-mcp-config` generates this form.
- REA needs Node 22.19+, 24.11+, or 26+ (`bt rea-doctor` checks).
- Run one-off Node CLIs through `bt run-limited` so output and time are capped.

## Shared GPU caution (RTX 3090, 24 GB, also used by the local LLM)

- The model server holds most VRAM. Do not start GPU-heavy builds, training, or inference tests without checking free VRAM (`nvidia-smi`).
- Prefer CPU-only test runs. Do not unload or restart the model server unless the user asks.

## Safety

- Never run `format`, `diskpart`, registry edits, or system-wide changes without explicit authorization.
- Do not delete outside the project directory.
- Show the exact command before a destructive operation and wait for authorization.

## Tools

- `bt env-check` : OS, PowerShell version, toolchain versions, git state, VRAM in one call.
- `bt gpu-status -MinFreeMB 2500` : verdict before GPU-heavy work (exit 1 means low VRAM).
- `bt line-endings` : CRLF/LF/BOM report.
- Launcher: `bt.cmd` works in cmd.exe and PowerShell; it runs scripts with a per-process execution-policy bypass only for these local scripts. Install with `powershell -ExecutionPolicy Bypass -File tools\install.ps1 -AddToPath`.
- Quote comma lists: `-Files "a.cs,b.cs"`.
