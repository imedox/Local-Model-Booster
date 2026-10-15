# 1-Click Turnkey Automated Installer

**Target System**: Windows 10/11 x64  
**Hardware Target**: NVIDIA GeForce RTX 3090 24GB + 32GB RAM  
**Target Model**: `HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF`  
**Server & Runtime**: Bionic (`http://localhost:1235/v1`) & Billion-Context Proxy (`http://127.0.0.1:8787`)  

---

## What Does This 1-Click Installer Do?

When you double-click **`install.bat`** (or run `install.ps1` from PowerShell), it performs the entire end-to-end setup automatically:

1. **Prerequisite Check**: Validates Windows, Node.js / npm, LM Studio / Bionic, and model file availability.
2. **Billion-Context Daemon**: 
   - Automatically installs `billion-context` via npm globally.
   - Writes the optimized configuration (`128K` context, port `8787`).
   - Registers a silent Windows Scheduled Task (`BiliProxyService`) so it starts automatically on Windows boot.
   - Immediately starts the background daemon.
3. **MCP Server Integration**: Configures `billion-context` inside `~/.lmstudio/mcp.json`.
4. **Deploy Profiles & Switchers**:
   - Deploys the 6 production-tuned JSON profiles to `C:\tools\profiles\`.
   - Deploys `switch_profile.ps1` and individual 1-click desktop batch switchers (`switch_coding.bat`, `switch_tool_use.bat`, etc.) to `C:\tools\`.
   - Adds `C:\tools` to your Windows User PATH.
   - Immediately activates the default **`01_coding`** profile.
5. **Deploy Bionic Skills**:
   - Deploys all 33 tuned skills (including the master **`bionic-booster`**) into Bionic's global skills directory (`~/.lmstudio/skills`).
   - Deploys the 35 Model-Booster helper CLI tools (`bt.cmd`).
6. **Documentation**: Copies `Tutorial.md`, `README.md`, `TEST_PROMPTS.md`, and hardware tuning specs into `C:\tools\docs\`.
7. **Self-Verification**: Runs automatic connection tests against port 8787 and port 1235 and outputs a verified status table.

---

## How to Run:

Simply **double-click** on:
```text
install.bat
```
*(Or in PowerShell: `powershell -ExecutionPolicy Bypass -File install.ps1`)*

---

## Folder Contents

- **`install.bat`**: Double-click Windows batch launcher.
- **`install.ps1`**: The complete PowerShell automation script.
- **`configs/`**: All 6 tuned profile configurations (`01_coding` through `06_max_speed`).
- **`skills/`**: The complete suite of tuned Bionic skills (`bionic-booster`, `booster-core`, etc.).
- **`tools/`**: `switch_profile.ps1`, batch switchers, and `bt.cmd` helper tools.
- **`docs/`**: `Tutorial.md`, `README.md`, `TEST_PROMPTS.md`, and `LMSTUDIO-3090-TUNING.md`.
