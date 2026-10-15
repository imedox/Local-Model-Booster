# The Complete Beginner's Guide: Local 128K LLM Setup, Billion-Context & Profiles

A clear, step-by-step guide designed for beginners. If you ever forget how everything connects, just follow this document step by step!

---

## 1. System Overview (How the Pieces Fit Together)

1. **Hardware**: 
   - **GPU**: NVIDIA RTX 3090 24GB GDDR6X
   - **System RAM**: 32 GB DDR5
   - **OS**: Windows 10 x64 (Ghost Spectre)
2. **Model**: 
   - `HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF`
   - File: `I:\LM-Studio-Models\HauhauCS\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf`
   - Target Context Length: **128K (131,072 tokens)**
3. **Inference Server**: 
   - **Bionic** (built on LM Studio runtime), exposing OpenAI API at: `http://localhost:1235/v1`
4. **Context Manager**: 
   - **Billion-Context (`bili`)**: Proxy running on `http://127.0.0.1:8787` that compresses long conversations to prevent VRAM overflow.

---

## 2. Permanent Default Configuration: `01_coding`

By default, the model is permanently configured with the **`01_coding`** profile. 
This is your **all-around daily driver** that handles coding, deep reasoning, general chat, and tool-calling with top performance:

- **Context Window**: `131,072` tokens (128K)
- **Flash Attention**: `true` (Enabled)
- **KV Cache Quantization**: `q8_0` (Both K and V cache)
- **GPU Offload**: 100% (All 65 layers on RTX 3090)
- **FastMTP Speculative Decoding**: Enabled (~54–58 tokens/sec)
- **Reasoning Budget**: 16,384 tokens (Deep step-by-step planning)

### Recommended Clean System Prompt:
Keep the system prompt clean and focused on your work (no hardware commands):

```text
You are an expert AI software engineer. When the user asks for code, implementations, or refactoring, provide clean, idiomatic, and complete code with clear explanations. Do not scan directories unless explicitly asked.
```

---

## 3. Alternative Profiles & Pure Bionic Switching

The AI model should **never** switch its own hardware profiles during a chat (unloading VRAM mid-conversation causes freezes and memory loss). 

If **YOU (the user)** want to switch profiles for a specialized task before you begin chatting, run the switcher script from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\tools\switch_profile.ps1" -Profile <name>
```

### Important Fixes in `switch_profile.ps1`:
- **100% Bionic Native**: The script operates solely through direct file updates. It does **not** invoke `lms` CLI commands, meaning **LM Studio will never open or interfere**.
- **Dual-Path Sync**: The script simultaneously updates both Bionic's internal runtime config and its UI model configuration file:
  - `C:\Users\Administrator\.lmstudio\apps\bionic\.internal\user-concrete-model-default-config\...`
  - `C:\Users\Administrator\.lmstudio\.internal\user-concrete-model-default-config\...`

### Profile Catalog:

| Profile Name | Command | When to Use It |
| :--- | :--- | :--- |
| **`coding`** *(Default)* | `.\switch_profile.ps1 -Profile coding` | Everyday coding, bug fixes, refactoring, and general chat. |
| **`general_operation`** | `.\switch_profile.ps1 -Profile general_operation` | Casual assistant work, shorter 8K reasoning budget. |
| **`tool_use`** | `.\switch_profile.ps1 -Profile tool_use` | Strict JSON output, low temperature (0.3), API tool calls. |
| **`long_tasks`** | `.\switch_profile.ps1 -Profile long_tasks` | Very large codebases (>50K tokens); uses `q4_0` KV cache for maximum VRAM safety. |
| **`max_intelligence`** | `.\switch_profile.ps1 -Profile max_intelligence` | Hard mathematical proofs and complex algorithmic riddles (24K reasoning budget). |
| **`max_speed`** | `.\switch_profile.ps1 -Profile max_speed` | Maximum throughput (~68–75 t/s) with reasoning turned off. |

---

## 4. Billion-Context Setup & Auto-Start

### Installation:
```powershell
npm install -g billion-context
```

### Config File Location:
`C:\Users\Administrator\.config\billion-context\billion-context.json`

```json
{
  "port": 8787,
  "host": "127.0.0.1",
  "providers": {
    "http://127.0.0.1:1235": {
      "models": {
        "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp": {
          "context": 131072
        }
      }
    }
  }
}
```

### Automatic Background Startup:
The proxy is registered as a Windows Scheduled Task (`BiliProxyService`) that launches automatically upon login.

- **Web Dashboard**: `http://localhost:8787/__bili/`
- **Live Stats**: `http://localhost:8787/__bili/stats`
- **Log File**: `C:\Users\Administrator\.local\state\billion-context\bili.log`

---

## 5. Billion-Context MCP Setup (LM Studio & Antigravity IDE)

### Critical Setup Notes:
1. **Escape Paths Correctly**: Never use quadruple backslashes (`\\\\`). Use standard single backslashes in path arguments:
   `C:\\Program Files\\nodejs\\node.exe` and `C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node_modules\\billion-context\\dist\\mcp.js`.
2. **Proxy Must Be Running**: The MCP server (`dist/mcp.js`) connects to port `8787` on launch. Always ensure `bili` is active.

### Antigravity IDE MCP Config:
File: `C:\Users\Administrator\.gemini\config\mcp_config.json`
```json
{
  "mcpServers": {
    "billion-context": {
      "command": "C:\\Program Files\\nodejs\\node.exe",
      "args": [
        "C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node_modules\\billion-context\\dist\\mcp.js"
      ]
    }
  }
}
```

---

## 6. Remote Ubuntu & Coolify Integration (Quick Reference)

- **Ubuntu Host**: `192.168.1.5` (User: `imedox`, sudo pass: `0000`)
- **Direct SSH Access**: `ssh imedox@192.168.1.5` (pre-authenticated with ED25519 key)
- **Windows Local Shared Folder**: `C:\Users\Public\SharedFolder` mounted on Ubuntu at `/mnt/sharedfolder`
- **Coolify MCP**: `http://192.168.1.5:8000/mcp/`

---

## 7. Troubleshooting Quick Table

| Problem | Cause | Quick Fix |
| :--- | :--- | :--- |
| **"bili proxy unreachable at 127.0.0.1:8787"** | The background daemon stopped | Run: `Start-Process "C:\Program Files\nodejs\node.exe" -ArgumentList '"C:\Users\Administrator\AppData\Roaming\npm\node_modules\billion-context\dist\index.js" start' -WindowStyle Hidden` |
| **LM Studio MCP stuck on "Connecting..."** | Port 8787 is down or path escaping has `\\\\` | Verify `bili` is running, then verify clean paths in `~/.lmstudio/mcp.json`. |
| **Out of Memory (OOM) on 128K** | KV cache was set to FP16 or parallel slots > 1 | Ensure `kCacheQuantizationType` and `vCacheQuantizationType` are `q8_0` or `q4_0`, and `numParallelSessions: 1`. |
| **Model returns empty reasoning** | `max_tokens` was set too low in client | Ensure client `max_tokens` is at least 4096 so reasoning traces have room to complete before final answer. |


---

## 8. One-Click Desktop Switchers (.BAT) & Test Prompts

You have individual `.bat` files saved in `C:\tools\` (and in `target_tuning\scripts\`). You can simply **double-click** any of them:

- **`switch_coding.bat`**: Switches to default `01_coding` profile.
- **`switch_general_operation.bat`**: Switches to `02_general_operation`.
- **`switch_tool_use.bat`**: Switches to `03_tool_use`.
- **`switch_long_tasks.bat`**: Switches to `04_long_tasks`.
- **`switch_max_intelligence.bat`**: Switches to `05_max_intelligence`.
- **`switch_max_speed.bat`**: Switches to `06_max_speed`.

See [TEST_PROMPTS.md](docs/TEST_PROMPTS.md) for the exact prompt to test each profile.

---

## 9. Bionic Skills & Model-Booster Integration

Bionic has native support for Claude-compatible agent skills. Skills live in `~/.lmstudio/skills` and are accessible across all Bionic projects.

### What is Model-Booster?
Model-Booster is a specialized suite of **33 skills** designed to turn local models (like our Qwen 3.8-27B on RTX 3090) into disciplined, evidence-driven software engineers.

### Critical Fixes Applied for Qwen 3.8 & Our RTX 3090:
1. **In-Memory Loop Guard (Zero Reasoning Loops)**: 
   - *Problem*: The original Claude pack instructed the model to run external PowerShell scripts (`bt loop-check`, `bt calc-score`, `bt estimate-tokens`) for routine self-evaluation. On Qwen 3.8 thinking mode, this trapped the model in 40–90 second thinking loops!
   - *Fix*: Loop detection is now evaluated **100% in-memory**. If the exact same action or error occurs twice, the model stops immediately and switches strategy without spawning external processes.
2. **Thinking Budget Ceilings**:
   - *Problem*: Qwen 3.8 retains past reasoning blocks (`preserve_thinking: true`). Long 16K–32K thinking traces filled the context after just 3–4 turns.
   - *Fix*: Set razor-sharp, decision-oriented CoT ceilings: 500–1,500 tokens for simple edits; 1,500–4,000 tokens for multi-file features.
3. **128K Context & Billion-Context Proxy Integration**:
   - *Problem*: The original pack assumed 64K–98K and manual text truncation.
   - *Fix*: Fully adapted for 131,072 context with `q8_0` KV cache and integrates the local Billion-Context proxy (`http://127.0.0.1:8787`) using MCP tools (`compress`, `search_context`).
4. **Master All-in-One Skills**:
   - Added **`bionic-booster`** (and alias `model-booster`) which consolidates all core capabilities into a single toggleable master skill.

### Recommended Activation Policy (CRITICAL):
> [!IMPORTANT]
> **Keep ONLY `Bionic Booster` activated in Bionic Settings!**
> 
> - **Why?** If all 33 skills are enabled simultaneously, Bionic injects ~5,000 characters of skill descriptions into the system prompt on **every single message**. This bloats the prompt, wastes context tokens, and causes local models to overthink and hesitate.
> - **Everything in One**: `Bionic Booster` is a master consolidated skill that already includes:
>   1. The 5-Phase loop (`UNDERSTAND -> PLAN -> ACT -> VERIFY -> REPORT`)
>   2. Qwen 3.8 tuned thinking budget (500–4,000 tokens)
>   3. 128K context & Billion-Context proxy coordination
>   4. In-memory zero-loop guard (hard stop on 2 repeat failures)
>   5. Surgical code editing and Windows PowerShell standards
> - **How to configure in Bionic**:
>   1. Open Bionic $\rightarrow$ Click **Settings** (gear icon bottom left) $\rightarrow$ **Skills** (*Compétences Bionic*).
>   2. Click the three dots (**`...`**) next to the other skills and uncheck **"Activer cette compétence"**.
>   3. Leave the checkmark **ON** only for **`Bionic Booster`**.
> - **On-Demand Skills**: You can still summon any modular skill in chat at any time by typing `@` (e.g., `@git-checkpoints`, `@security-review`, or `@agent-auto`).

---

## 10. The Turnkey 1-Click Automated Installer

If you ever reinstall your system, set up a new machine, or want to restore the entire configuration in seconds, you do not need to follow each step manually.

### Installer Location:
- Workspace: `C:\Users\Administrator\Documents\Workspace\Local-bunchmark\1-Click-Installer\`
- Tool Docs: `C:\tools\docs\`

### How to Run:
Simply **double-click** on:
```text
C:\Users\Administrator\Documents\Workspace\Local-bunchmark\1-Click-Installer\install.bat
```

### What `install.bat` Does Automatically:
1. **Checks Prerequisites**: Confirms Windows, Node.js, LM Studio / Bionic, and target model existence.
2. **Installs Billion-Context**: Installs the npm package globally, writes `billion-context.json` (128K context, port 8787), registers the silent Windows Scheduled Task `BiliProxyService`, and starts the daemon immediately.
3. **Configures MCP**: Injects the Billion-Context MCP server into `~/.lmstudio/mcp.json`.
4. **Deploys Profiles**: Copies all 6 JSON configs to `C:\tools\profiles\`, installs `switch_profile.ps1` and individual desktop `.bat` switchers to `C:\tools\`, adds `C:\tools` to User `PATH`, and sets `01_coding` as active.
5. **Deploys Bionic Skills & Tools**: Copies all 33 tuned skills (including `bionic-booster`) to `~/.lmstudio/skills\` and deploys all 35 helper tools and `bt.cmd` into `C:\tools\`.
6. **Verifies Connectivity**: Performs TCP health checks against port 8787 and port 1235 and displays a green verified report.

---

## 11. Skill Helper Tools (`C:\tools\bt.cmd`) & Preventing Skill Degradation

When an agent skill is triggered, the skill instructions tell the model to use specialized tools for safe, high-precision operations (such as mapping a repo or running tests).

### Where Are the Tools Located?
- Directory: `C:\tools\`
- Launcher: `C:\tools\bt.cmd` (calls `bt.ps1`)
- Added to: Both **Windows User PATH** and **System Machine PATH**.

### Why Tool Availability Prevents Skill Degradation:
If the agent is told by a skill to run `bt repo-map` or `bt run-checks`, but the script is not installed or not in PATH, the agent encounters a `"command not found"` error. When this happens:
1. The agent falls back to guessing or trying to write huge PowerShell scripts from scratch.
2. The agent degrades, wastes reasoning tokens, and risks hallucinations.

Because all 35 tools are installed directly in `C:\tools\`, both `bt <tool>` and `C:\tools\bt.cmd <tool>` are 100% available to any agent across all directories.

### Essential Tools Quick Reference:
| Tool Command | Purpose | Output Guard |
| :--- | :--- | :--- |
| `bt repo-map` | Generates a high-density structural outline of any repository. | Capped at 150 lines |
| `bt read-range -Path <f> -Start <N> -End <M>` | Reads surgical line slices instead of dumping large files. | Max 400 lines |
| `bt find-symbol -Pattern "X"` | Fast symbol and text search across the codebase. | Capped search |
| `bt run-checks` | Detects .NET, Node, or Python and runs build/test suites. | 120s timeout |
| `bt gpu-status` | Checks free VRAM on the RTX 3090 before launching local tasks. | Safe VRAM verdict |
| `bt git-checkpoint` | Creates safe branch and commit checkpoints before risky edits. | Isolated commits |
| `bt find-leftovers` | Scans for stubbed code, unfinished TODOs, and placeholder `...`. | Clean verification |

---

## 12. GitHub MCP Server Integration

Antigravity and LM Studio / Bionic both support GitHub tool integration through the Model Context Protocol (MCP).

### What Was Configured:
- **Package**: `@modelcontextprotocol/server-github` (installed globally via npm)
- **Script Path**: `C:\Users\Administrator\AppData\Roaming\npm\node_modules\@modelcontextprotocol\server-github\dist\index.js`
- **Config Files**:
  - Antigravity: `~/.gemini/config/mcp_config.json`
  - LM Studio / Bionic: `~/.lmstudio/mcp.json`

### Registered GitHub MCP Tools (26 Tools):
- **Repositories**: `search_repositories`, `create_repository`, `fork_repository`
- **Files & Branches**: `get_file_contents`, `create_or_update_file`, `push_files`, `create_branch`
- **Issues & PRs**: `create_issue`, `get_issue`, `list_issues`, `update_issue`, `add_issue_comment`
- **Pull Requests**: `create_pull_request`, `list_pull_requests`, `merge_pull_request`, `create_pull_request_review`
- **Search & Commits**: `search_code`, `search_issues`, `search_users`, `list_commits`

### Adding Your Personal Access Token (PAT):
The server works with public repositories out of the box. To access private repositories or create pull requests, open `~/.gemini/config/mcp_config.json` and insert your token:
```json
"github": {
  "command": "C:\\Program Files\\nodejs\\node.exe",
  "args": [
    "C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node_modules\\@modelcontextprotocol\\server-github\\dist\\index.js"
  ],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_yourTokenHere"
  }
}
```


