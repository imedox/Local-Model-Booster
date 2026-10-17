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
          "context": 98304
        }
      }
    }
  }
}
```

> [!TIP]
> **Why declare 98,304 instead of 131,072 in Billion-Context?**
> Billion-Context scales its automatic compression pressure bands (45%, 75%, and 95%) directly from this number. Declaring the **true sustainable window (98,304)** ensures compression begins actively protecting your VRAM around **~44,000 tokens** (45% threshold), well before the RTX 3090 (24GB) experiences memory pressure under the 27B weights + `q8_0` KV cache.

### Automatic Background Startup:
The proxy is currently registered as a Windows Scheduled Task (`BiliProxyService`) that launches automatically upon login.

> [!NOTE]
> *Upcoming Enhancement*: Billion-Context PR #3176 / Issue #3178 introduces first-class service management (`bili service install|status|restart|remove`). Once merged upstream, the 1-click installer will adopt the native CLI service.

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

> [!NOTE]
> **Claude Code CLI is Optional**: The 1-click automated installer is designed to configure the native **Bionic / LM Studio** agent runtime, the background Billion-Context daemon, and all helper CLI tools. It **does NOT** install Claude Code CLI.
> If you wish to use Claude Code CLI, it is completely optional: simply follow the instructions in [Section 14](#14-claude-code-cli--lm-studio--billion-context-integration) or the complete guide in [docs/CLAUDE_CODE.md](CLAUDE_CODE.md).

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

---

## 13. Automated Skill Validation (`scripts/validate_skills.py`)

To ensure skills remain stable, error-free, and fully integrated with the tools suite, a Python validation script is provided.

### When to Run:
- Before committing any changes or submitting a PR.
- Whenever you edit `SKILL.md` frontmatter, add a new skill, or modify tools in `tools/`.

### Run Command:
```bash
python scripts/validate_skills.py
```

### Verification Checks:
1. **Frontmatter Integrity**: Checks YAML formatting, ensures folder name matches `name` property, and checks allowed properties (`name`, `display-name`, `description`, `disable-model-invocation`, `user-invocable`).
2. **Description Length**: Validates that descriptions are between 40 and 1,024 characters.
3. **Diagrams**: Confirms that every skill has an accompanying `diagram.mmd` Mermaid flow.
4. **Tool Linkage**: Parses every `SKILL.md` for `bt <tool>` calls and checks that `tools/<tool>.ps1` exists.

---

## 14. Claude Code CLI + LM Studio + Billion-Context Integration

You can easily route Anthropic's official **Claude Code CLI** to your local LM Studio / Bionic server through the **Billion-Context** proxy on Windows.

### Architectural Flow:
```text
Claude Code CLI (terminal)
   │
   ▼ ANTHROPIC_BASE_URL: http://127.0.0.1:8787/bili/http://127.0.0.1:1235
Billion-Context Proxy (:8787)
   │ (compress turns on-the-fly at 45% / 75% thresholds)
   ▼ Anthropic /v1/messages forwarding
LM Studio / Bionic (:1235)
   │
   ▼ (Qwen 3.8 27B, 128K context, q8_0 KV cache)
RTX 3090 / GPU
```

### Essential Settings (`~/.claude/settings.json`):
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787/bili/http://127.0.0.1:1235",
    "ANTHROPIC_AUTH_TOKEN": "lmstudio",
    "ANTHROPIC_MODEL": "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0",
    "DISABLE_AUTO_COMPACT": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "NO_PROXY": "127.0.0.1,localhost"
  },
  "model": "qwen3.8-27b-uncensored-hauhaucs-aggressive-mtp"
}
```

### Smart Multi-Session Lifecycle Wrapper:
The PowerShell profile functions track active Claude Code sessions using temporary PID markers in `%TEMP%\bili-sessions`:
- Automatically launches `bili` in the background when the first Claude session opens.
- Keeps `bili` running safely if multiple terminal windows are opened simultaneously.
- Gracefully terminates `bili` when the last active Claude session exits.

Launch with:
```powershell
bclaude
```

📖 **Detailed Setup & Troubleshooting Guide**:
For step-by-step reproduction instructions, PowerShell profile code, background services, and troubleshooting, read [docs/CLAUDE_CODE.md](CLAUDE_CODE.md).

---

## 15. REA Meta-Gateway & Reverse Engineering Arsenal

### The 262K Context Overflow Problem
When configuring the raw `rea-agents` MCP server (`npx -y rea-agents@latest mcp`), 207 detailed tool definitions are injected into the agent's system prompt. This consumes **262,751 tokens** before the user even types a single word, immediately exceeding the 128K context window of local models.

### The Meta-Gateway Architecture (912 Tokens, 100% Access)
The **REA Meta-Gateway** (`C:\tools\rea_gateway_mcp.py`) exposes only **5 surgical meta-tools**, slashing prompt overhead by **99.6%** down to **912 tokens**, while preserving complete access to the full reverse engineering suite:

| Meta-Tool | Purpose | LLM Signature |
| :--- | :--- | :--- |
| `rea_catalog` | Discover any of the 207 REA capabilities or binary tools | `(filter?: string)` |
| `rea_run` | Execute any tool command with NVMe interception | `(tool_name: string, command: string, cwd?: string)` |
| `rea_search_evidence` | Sub-millisecond FTS5 search across captured outputs | `(query: string, evidence_id?: string, limit?: int)` |
| `rea_read_chunk` | Surgical line-range reading from NVMe storage | `(evidence_id: string, start_line: int, end_line: int)` |
| `rea_export_ida` | Generate color-coded IDAPython patch script | `(annotations: list, output_path?: string)` |

### NVMe SQLite FTS5 Evidence Store (`C:\REA-Context\`)
Large analysis dumps (disassemblies, imported symbols, entropy listings) are never dumped directly into the conversation context. Instead:
1. They are streamed directly into high-speed NVMe storage at `C:\REA-Context\sessions\<session-id>\raw\`.
2. Full text is indexed in SQLite FTS5 for instant keyword and address lookups (< 11 ms on 20,000+ line listings).
3. The LLM receives only a compact metadata summary (< 120 tokens) with an `Evidence ID` (e.g. `EV-0001`).

### Color-Coded IDAPython Export (`Alt + F7`)
When reverse engineering without an active IDA Pro instance, findings can be exported to `C:\REA-Context\ida_patch.py` via `bt re-ida-export` or MCP `rea_export_ida`. When loaded into IDA Pro, functions and basic blocks are highlighted using standard triage colors:
- 🔴 **Red (`0x3333ff`)**: Injection, Hooking & Stealth Routines.
- 🟠 **Orange (`0x0078ff`)**: Cryptography, Decryption & Obfuscation.
- 🔵 **Blue (`0xff8000`)**: Network C2, Sockets & Data Exfiltration.
- 🟢 **Green (`0x33cc33`)**: Safe & Normal initialization routines.

### Dual MCP Registry Configuration
The 1-Click Installer (`installer/install.ps1`) automatically registers the REA Meta-Gateway in both:
- **LM Studio**: `~/.lmstudio/mcp.json`
- **Bionic Agent Internal**: `~/.lmstudio/apps/bionic/.internal/ng-mcp.json` (written without UTF-8 BOM to prevent Node.js JSON parse errors).





