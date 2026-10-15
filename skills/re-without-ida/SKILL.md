---
name: re-without-ida
display-name: RE Without IDA
description: Reverse engineering without IDA Pro. Uses offline PE/ELF triage, string recovery, ASAR extraction, Ghidra, and CLI decompilers safely.
---

# Reverse Engineering Without IDA

Precondition: `bt re-mode` shows `without-ida`. Never use the IDA provider in this mode (the tools refuse it).

## Capability ladder

| Target | Tooling | Depth |
|---|---|---|
| Electron / JavaScript / ASAR | REA `analyze_javascript_application`, or `bt re-asar` + `bt find-symbol` | Full: modules, imports, IPC, routes |
| .NET assemblies | REA `inspect_managed_artifact`; `bt re-triage`; `bt inspect-dotnet` | Metadata and CIL (static) |
| APK / MSIX / ZIP | REA `inventory_artifact`; `bt re-archive` | Inventory, manifests; decompile needs JADX + JDK |
| Websites, HAR/SAZ captures | REA browser/capture tools | Structure, scripts, requests |
| Native PE/ELF | REA + Ghidra (experimental on Windows) or Hopper; else offline triage only | Pseudocode only with a real engine |
| Anything native, no engine | `bt re-triage`, `bt re-strings`, imports, entropy | Shallow: no decompilation |

## Honest limits

- No decompiler means no pseudocode. Do not invent function bodies from strings and imports. Say "static triage only" and list what an engine would add.
- Packed or high-entropy samples: coverage incomplete; say so.

## Native with Ghidra (optional)

1. Check: `bt rea-doctor -Provider ghidra` (needs Ghidra, a full JDK; REA support on Windows is experimental).
2. Large binaries: set `REA_GHIDRA_STARTUP_TIMEOUT_MS` higher.
3. MCP registration: `bt rea-mcp-config -Provider ghidra -Out "$env:USERPROFILE\.lmstudio\mcp.json"` (verify the path of the host's `mcp.json`; a backup is created).
4. CLI query: `bt rea-run -Command function -Target <exe> -Name <func> -Provider ghidra`.

## Setup plan (user approves and runs)

`bt rea-setup-plan` prints the exact commands. Node 22.19+, 24.11+, or 26+ is required (`bt rea-doctor`).

## Workflow

1. Triage: `bt re-triage`, `bt re-strings -Preset url|path|cmd`.
2. Route by target type (rea-reverse-engineering section 1).
3. Log evidence with `bt re-evidence` (re-evidence-discipline).
4. Report: observations, inferences, unknowns, and "what IDA/Ghidra would add".
5. If the user wants deeper native analysis, offer to switch to with-ida (ask; do not switch silently).
