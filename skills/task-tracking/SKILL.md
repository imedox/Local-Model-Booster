---
name: task-tracking
display-name: Task Tracking
description: Maintain explicit checklist plans in .agent/PLAN.md for tasks with 3+ steps. Updates status in real-time and logs verification evidence per milestone.
---

# Task Tracking

## Create the plan before the first edit

File: `.agent/PLAN.md` (or in-conversation if file writes are not allowed).

```
# PLAN: <task in one sentence>
## Acceptance
- [ ] A1 (w=3) <observable outcome> | evidence: <how verified>
- [ ] A2 (w=2) ...
## Steps
- [ ] S1 <verb + object + file>   (A1)
- [ ] S2 ...
## Status
IN PROGRESS: S1
BLOCKED: none
LAST VERIFIED: <command + result>
```

## Rules

1. Steps are small: one coherent edit or one check each. If a step needs "and", split it.
2. Exactly one step is IN PROGRESS.
3. Mark a step done only after its check ran. Record the evidence next to it.
4. When a new requirement or defect appears, add it as a new step; never silently drop steps.
5. If the plan is wrong, edit it and note why in one line.
6. Re-read PLAN.md before each new step in long runs and after any compaction.
7. Final answer must be consistent with PLAN.md: every unchecked box is reported as incomplete.

## Status words

`todo` / `doing` / `done-unverified` / `verified` / `failed` / `blocked`. Use them literally.

## Step sizing guide

- 3-10 steps for a typical task. More than 12: group into phases and plan one phase at a time.
- Put the verification step immediately after each risky edit, not only at the end.

## Tools

- `bt agent-init` : creates `.agent\PLAN.md` from the template and keeps `.agent/` out of git.
- `bt plan-update -Id S2 -Status doing` / `-Status done -Evidence "dotnet test: passed"` : updates the checkbox, status suffix, and status block exactly.
