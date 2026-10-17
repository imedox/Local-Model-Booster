---
name: rea-reverse-engineering
display-name: REA Reverse Engineering
description: Reverse engineer native binaries, .NET assemblies, and Electron apps using REA tools. Enforces static triage before dynamic execution.
---

# REA: Reverse Engineer Anything (Windows, local model)

Adapted and condensed from the `reverse-engineer-anything` skill of REA (github.com/morluto/rea, MIT). See `references/ATTRIBUTION.md`.

## 0. Preconditions

1. `bt re-mode` shows a recorded mode. If not: load `re-mode-gate` and ask the user. Do nothing else.
2. Use REA only when a claim depends on a shipped binary/package, decompilation, passive runtime evidence, controlled replay, or behavior not established by available source. For a complete source repository use normal repo tools (repo-exploration).
3. Analysis runs locally; targets are read, not uploaded. Static analysis does not run the app.

## 1. Route the target first

| Target | First step |
|---|---|
| ASAR or extracted JavaScript/Electron tree | `analyze_javascript_application` (CLI: `analyze-javascript-application`); offline: `bt re-asar` |
| Archive, APK/IPA/MSIX/AppX/ZIP/DMG | `inventory_artifact`; offline: `bt re-archive` |
| Managed PE/CLI (.NET) | `inspect_managed_artifact`; offline: `bt re-triage` then `bt inspect-dotnet` |
| Browser page already open (user-owned) | `list_browser_targets` |
| Electron runtime already open (user-owned) | `list_electron_targets` |
| Native executable, library, or analysis DB | `open_binary` then `binary_overview`; offline: `bt re-triage`, `bt re-strings` |

Do not call `open_binary` unless the target is native. If the user did not name a target, ask which app to inspect; never pick an example app yourself. Resolve a human app name to one installed artifact when possible; ask only if ambiguous.

## 2. MCP or CLI
 
- MCP tools exist only if the REA server is registered in the host (LM Studio / Hermes). Check the tool list first.
- Context Protection: Do NOT register raw REA with 200+ tools directly in the client (which injects ~260K tokens). Always use the `rea-gateway` MCP server (`C:\tools\rea_gateway_mcp.py`) which exposes 5 surgical tools (`rea_catalog`, `rea_run`, `rea_search_evidence`, `rea_read_chunk`, `rea_export_ida`) and routes raw dumps into the NVMe SQLite FTS5 store.
- No MCP, or context is tight: use the CLI through `bt rea-run` (timeout, capped output, mode rules built in). The CLI uses the same workflows.
- Export IDAPython patches at completion via `bt re-ida-export`.
 
 ## 3. Work summary-first (important for a small context)
 
 - Start with the default summary projection. Never repeat an identical call.
 - Do not fetch full Evidence or a full application graph unless one specific claim needs detail missing from the summary. Follow the paged resource URIs and fetch only the relevant page.
 - Record findings with `bt re-evidence` (see re-evidence-discipline): observation, inference, unknown.
 - Cite evidence IDs and keep limitations. Static analysis never proves execution.
 
 ## 4. Read only the relevant guide
 
 - Native binaries, managed assemblies, archives: `references/native-and-artifacts.md`
 - ASAR, JavaScript, feature tracing, version comparison: `references/javascript-applications.md`
 - Passive browser/Electron observation: `references/runtime-observation.md`
 - Evidence paging, comparisons, unknowns, verification: `references/evidence-workflows.md`
 - Controlled replay: `references/controlled-replay.md`
 
 ## 5. Readiness (only when something fails)
 
 If REA tools are available, use them directly; do not run diagnostics every task. If the server is missing or stale: `bt rea-doctor` (add `-Provider ida|ghidra`). Propose setup only with the exact plan from `bt rea-setup-plan` and get the user's approval before anything writes configuration. Restart/reload MCP after registration changes. The CLI works immediately.
 
 ## 6. Guardrails
 
 - Authorized, lawful targets only (re-mode-gate). No license/key bypass, cracking, malware development, or detection evasion.
 - Redact secrets found in strings or captures; report their existence and location, not their values.
 - Runtime capture runs or interacts with the target under the user's permissions: get explicit approval first and prefer passive observation.
 - Obfuscated or packed targets: say coverage is incomplete (`bt re-triage` flags high entropy).
 
 ## 7. Finish
 
 Explain findings in plain language tied to evidence IDs. When asked to build something, use normal coding tools and clearly separate observed behavior from design choices. Close native sessions with `close_binary`. Save the evidence log path in the final report.
 
 ## Tools
 
 `bt re-mode`, `bt rea-doctor`, `bt rea-run`, `bt rea-mcp-config`, `bt rea-setup-plan`, `bt re-triage`, `bt re-strings`, `bt re-asar`, `bt re-archive`, `bt re-diff-dirs`, `bt re-evidence`, `bt re-ida-export`.
