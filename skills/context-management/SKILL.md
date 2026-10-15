---
name: context-management
display-name: Context Management
description: Keep 128k context window reliable on RTX 3090. Coordinates memory zones, compacts state, and integrates Billion-Context daemon on port 8787 for semantic retrieval and long-term recall.
---

# Context Management (128K Native + Billion-Context)

## Hardware & Architecture Reality

The RTX 3090 24GB hosts `Qwen3.8-27B` with a **131,072 (128K)** native context window utilizing `q8_0` KV cache and Flash Attention. To preserve needle-in-a-haystack recall across extended engineering tasks, prevent context saturation through active discipline and the Billion-Context proxy.

## Context Zones (at 128K tokens)

| Zone | Usage | Tokens Used | Action |
|---|---|---|---|
| **Green** | < 50% | 0 - 65,536 | Work normally with targeted tool reads. |
| **Yellow** | 50-65% | 65,536 - 85,000 | Stop reading new large material; summarize findings; invoke Billion-Context `compress`. |
| **Red** | > 65% | > 85,000 | Compact immediately: write `.agent/STATE.md`, offload completed phases to Billion-Context, continue from state. |

## Reading Rules

1. Search first (`Select-String`, `rg`, or native file search), then read only the matching line ranges (+/- 30 lines).
2. Never read an entire file over 300 lines without a specific architectural need. Read the symbols/outline first.
3. Cap tool output: limit terminal command output to essential lines. For logs, read the last 50-100 lines and filter for errors.
4. After reading, extract the key 3-5 facts and let intermediate raw dumps drop from active consideration.
5. Do not re-read files that were already read in the current conversation unless they have been modified.

## Billion-Context MCP Integration

The **Billion-Context Daemon** is running locally on port 8787 (`http://127.0.0.1:8787` via `BiliProxyService`). Use its MCP tools when context enters Yellow or Red zones:

- **`compress`**: Pass bulky historical execution logs or completed milestones to generate high-density hierarchical summaries.
- **`search_context`**: Semantically search past turns, code changes, or discarded hypotheses without having to re-read them in full.
- **`decompress`**: Re-expand specific historical context segments when fine-grained verification is required.
- **`acp_status`**: Verify proxy cache status and context compression ratio.

## Pinned State (Restate after compaction or every ~15 actions)

```
GOAL: <one concise sentence>
CONSTRAINTS: <hard prohibitions, environment limits>
ACCEPTANCE: <checklist ids and status>
DONE: <files created or modified>
NEXT: <single concrete next action>
```

## Compaction Procedure

1. Write `.agent/STATE.md` using `templates/STATE.md`.
2. Include: goal, constraints, architectural decisions, files touched, working commands, failed attempts and why, and the single next step.
3. Leverage Billion-Context `compress` to archive previous steps.
4. Continue from `.agent/STATE.md`. If a fresh session is needed, load only `STATE.md` plus the immediate files required for the next step.
