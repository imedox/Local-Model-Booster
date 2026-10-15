---
name: project-memory
display-name: Project Memory
description: Persist and reuse durable project knowledge across sessions in .agent/MEMORY.md. Tracks working patterns, architecture decisions, and environment quirks.
---

# Project Memory

## Files

- `.agent/MEMORY.md`: durable facts, max ~60 lines.
- `.agent/STATE.md`: current task handoff (see context-management).
- `.agent/PLAN.md`: current checklist (see task-tracking).

## Read at start

Read MEMORY.md if it exists. Treat entries as hints; re-verify anything cheap to check (a command, a path) before relying on it. If memory contradicts the repo, the repo wins and the entry is corrected.

## What to save

- Working build, test, and run commands (exact).
- Environment facts: SDK versions, OS quirks, required tools.
- Architecture notes: where things live, patterns used.
- Pitfalls: things that failed and why.
- User preferences: language, style, forbidden actions.

## What never to save

Secrets, tokens, personal data, raw logs, one-off task details, unverified guesses, long code.

## Format

```
# MEMORY
## Commands
- build: ...
- test: ...
## Environment
- ...
## Architecture
- ...
## Pitfalls
- <symptom> -> <cause> -> <fix>   (verified YYYY-MM-DD)
## Preferences
- ...
```

## Maintenance

- Update at task end: add new verified facts; delete stale ones; merge duplicates.
- One line per fact. Date the pitfalls.
- If the file passes 60 lines, compress or move detail into repo docs.

## Tools

- `bt agent-init` : creates `.agent\MEMORY.md` from the template.
- `bt memory-add -Section Pitfalls -Text "symptom -> cause -> fix"` : appends one dated line, dedupes, refuses secrets, warns above 60 lines.
