---
name: re-with-ida
display-name: RE With IDA
description: Reverse engineering with IDA Pro MCP. Coordinates function decompilation, cross-references, struct definitions, and type recovery through IDA.
---

# Reverse Engineering With IDA Pro MCP

Precondition: `bt re-mode` shows `with-ida`. The user supplies IDA Pro (licensed) and a working IDA MCP server. REA adapts that server; it does not install, activate, or license IDA, and bundles no IDA server.

## Prerequisites (verify, do not assume)

1. Licensed IDA Pro (headless idalib needs IDA Pro 9+) installed by the user.
2. A working `mrexodia/ida-pro-mcp` (attached to the IDA GUI, or headless database). REA's provider is contract-bound to that server; as of the docs checked (Oct 2026) Hex-Rays' own `ida-mcp` is a requested feature, not supported. Confirm with doctor.
3. An `ida-mcp.json` registration file (an `mcpServers` object with an `ida-pro-mcp` entry; the optional native bridge uses a `protocol: "native"` profile described in REA's `docs/ida-provider.md`).
4. Node 22.19+, 24.11+, or 26+.

Check everything: `bt rea-doctor -Provider ida -IdaConfig C:\analysis\ida-mcp.json`.

## Select the provider

- Shell: `$env:REA_IDA_MCP_CONFIG = "C:/analysis/ida-mcp.json"` and `$env:REA_ANALYSIS_PROVIDER = "ida"` (forward slashes are fine).
- MCP: `open_binary` with `provider_id: "ida"`; the registration env must contain `REA_IDA_MCP_CONFIG`. Generate the entry: `bt rea-mcp-config -IdaConfig C:\analysis\ida-mcp.json -Out "$env:USERPROFILE\.lmstudio\mcp.json"` (verify the host's `mcp.json` path; a backup is made).
- CLI: `bt rea-run -Command function -Target C:\x\program.exe -Name main -Provider ida`.
- Setup plan to show the user: `bt rea-setup-plan -IdaConfig <file>`.

## If IDA MCP tools are already in the tool list

The user may have `ida-pro-mcp` registered directly. You may use either that server or REA's adapter. Prefer REA when evidence IDs, summaries, and limits are wanted; do not open two sessions on the same database at once.

## Working rules

1. Triage first, cheaply: `bt re-triage`, `bt re-strings` (decide what to open).
2. `open_binary` once, `binary_overview`, then targeted functions, references, strings. Summary-first.
3. IDA provider in REA is read-only: do not promise patching or renaming.
4. Code cross-references do not prove call edges; do not report callers as established from xrefs alone (the modern profile omits direct callers for this reason).
5. Pseudocode comes from the user's decompiler; quote it as observation with evidence IDs. Reconstructed C is an inference until compared with original behavior.
6. Large/slow analysis: wait for IDA auto-analysis to finish; raise timeouts via `bt rea-run -TimeoutSec`.
7. Close the session (`close_binary`) when done so IDA is not left locked.

## Failure handling

- Doctor fails or IDA does not respond: report the exact error, check `REA_IDA_MCP_CONFIG`, and that IDA/ida-pro-mcp is running. Apply loop-guard after 2 tries.
- Still blocked: ask the user whether to continue WITHOUT IDA (re-without-ida). Wait for the answer; do not switch on your own.

## Log everything

Use `bt re-evidence` for each observation, inference (with basis), and unknown (re-evidence-discipline).
