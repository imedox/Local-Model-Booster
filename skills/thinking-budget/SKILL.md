---
name: thinking-budget
display-name: Thinking Budget
description: Allocate reasoning effort efficiently for Qwen3.8-27B. Sets razor-sharp decision-oriented CoT ceilings (500-4,000 tokens) to prevent thinking loops and KV cache bloat in multi-turn conversations.
---

# Thinking Budget for Qwen3.8-27B

## Size the task first (one line)

| Class | Examples | Thinking Budget | Native Tools |
|---|---|---|---|
| **Trivial** | rename symbol, explain a line, syntax question | <= 300 tokens | 0-1 |
| **Simple** | one-function change, localized bug, small script | 500 - 1,500 tokens | 1-4 |
| **Moderate** | multi-file feature, non-obvious bug, refactor | 1,500 - 4,000 tokens | 5-15 |
| **Hard** | complex architecture, tricky race condition, subtle defect | 4,000 - 8,000 tokens (16k max) | many, with STATE |

*Note on Qwen3.8*: Because `preserve_thinking: true` retains previous reasoning blocks across multi-turn sessions, keeping reasoning concise and decision-focused directly preserves KV cache capacity for 50+ turns without degradation.

## Compact thinking template

```
GOAL: ...
FACTS: (verified from files/commands only)
UNKNOWN: ...
OPTIONS: A / B (max 2-3)
DECISION: ... because ...
NEXT ACTION: one concrete step
```

Stop thinking immediately as soon as DECISION and NEXT ACTION are resolved.

## Rules

1. Think in decisions, not in continuous prose. No conversational narration of obvious steps.
2. Do not write the full solution in thinking and then write it again in the output. Draft code once.
3. Do not re-verify facts already confirmed by an earlier tool result.
4. Two options are enough unless both fail. Pick, act, observe.
5. Prefer a quick inspection (read lines, test run) over protracted deliberation.
6. If a thought restarts from the beginning or circles, apply loop-guard immediately.
7. Compute token estimates and checklist scores directly in-memory. Never spawn an external shell script just to calculate your own completion percentage.
8. When the budget is nearly spent, commit to the best-supported option and flag residual uncertainty.

## Self-consistency (for critical decisions)

Solve once, then verify against the explicit constraints list. If the check disagrees, pinpoint the exact conflicting assumption.
