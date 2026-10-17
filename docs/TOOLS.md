# Tools reference (Windows / PowerShell 5.1+)

Install once: `powershell -ExecutionPolicy Bypass -File tools\install.ps1 -AddToPath [-SkillsTarget "C:\path\to\skills"]`, then open a new terminal. Use `bt list` and `bt help <tool>`.
Without install: `tools\bt.cmd <tool> <args>`.

| Tool | Purpose | Used by skills |
|---|---|---|
| env-check | OS, shell, SDK versions, git, VRAM | booster-core, windows-dev-environment, agent-auto, programming-knowledge |
| gpu-status | Free VRAM verdict | windows-dev-environment, test-driven-validation |
| repo-map | Compact repo map | repo-exploration, agent-auto |
| find-symbol | Capped code search | repo-exploration, hallucination-guard, security-review |
| read-range | Line ranges and outline | context-management, precise-code-editing |
| tail-log | Last lines or error lines of logs | context-management, systematic-debugging |
| estimate-tokens | Context zone estimate | context-management, thinking-budget |
| run-limited | Command with timeout, cap, destructive block, evidence log | tool-use-discipline, test-driven-validation |
| run-checks | Auto build/test for .NET, Node, Python | test-driven-validation, agent-auto-evaluator |
| agent-init | Create .agent files | task-tracking, project-memory |
| plan-update | Update PLAN.md items | task-tracking |
| memory-add | Add dated fact to MEMORY.md | project-memory |
| git-checkpoint | Safe git branch/commit/restore | git-checkpoints |
| diff-summary | Diff stat and whitespace check | self-review, git-checkpoints |
| backup-files | Backup before edits | precise-code-editing |
| line-endings | CRLF/LF/BOM report and fix | windows-dev-environment, precise-code-editing |
| find-leftovers | Stubs and TODO scan | long-output-chunking, self-review |
| secret-scan | Masked secret scan | security-review |
| loop-check | Repetition detector | loop-guard, tool-use-discipline |
| calc-score | Exact completion and function scores | agent-auto-evaluator, function-quality-score |
| inspect-dotnet | List .NET types and members | programming-knowledge |
| deps-info | Declared dependencies and versions | programming-knowledge, web-research |
| fetch-page | Web page as plain text | web-research |
| re-mode | RE gate: record user's with-ida / without-ida choice and authorization | re-mode-gate (all re-* / rea-* tools refuse without it) |
| rea-doctor | Readiness: Node, IDA, ida-pro-mcp, Ghidra, Java, env vars; REA doctor per provider | rea-reverse-engineering, re-with-ida, re-without-ida |
| rea-mcp-config | Generate or merge REA MCP entry (cmd.exe wrapper) for LM Studio/Hermes, with backup | re-with-ida, re-without-ida |
| rea-setup-plan | Print exact REA setup plan for the chosen mode (user runs it) | rea-reverse-engineering |
| rea-run | REA CLI with timeout, capped output, mode-aware provider rules | rea-reverse-engineering |
| re-triage | Offline PE/ELF/ZIP triage: hashes, headers, sections, entropy, imports, signature | re-without-ida, rea-reverse-engineering |
| re-strings | ASCII/UTF-16 strings with offsets and presets (url, path, ip, registry, cmd, key) | re-without-ida |
| re-asar | List/extract Electron ASAR in pure PowerShell (zip-slip safe) | rea-reverse-engineering |
| re-archive | List/extract APK/JAR/MSIX/ZIP with flags (zip-slip safe) | rea-reverse-engineering |
| re-diff-dirs | Compare two extracted app versions by SHA256 | rea-reverse-engineering |
| re-evidence | Evidence log: OBS / INF (needs basis) / UNK | re-evidence-discipline |
| re-ida-export | Export reverse engineering findings to color-coded IDAPython script for IDA Pro (Alt + F7) | re-without-ida, rea-reverse-engineering, bionic-booster |
| skill-validate | Validate skill structure | maintenance |

Reverse-engineering tools (re-*, rea-*) require `bt re-mode -Set with-ida|without-ida -Authorized yes` first; they exit with code 5 until the user has answered. IDA, ida-pro-mcp, Ghidra and Hopper are installed and licensed by the user; REA and these tools never install or activate them.

Design rules: read-only by default; output capped; destructive actions refused without explicit switches; numbers parsed with invariant culture (safe on French/Arabic locales); scripts are ASCII only.

Files written: `.agent\evidence.log`, `.agent\calls.log`, `.agent\backup\`, `.agent\*.md` (only inside the project you run them in).
