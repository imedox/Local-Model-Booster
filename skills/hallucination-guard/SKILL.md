---
name: hallucination-guard
display-name: Hallucination Guard
description: Ground factual claims in tool evidence. Requires explicit labels (VERIFIED, INFERRED, UNKNOWN) for files, APIs, versions, numbers, and test results.
---

# Hallucination Guard

## Certainty labels

- VERIFIED: observed in this session via a tool, file read, or command output.
- INFERRED: reasoned from verified facts; state the reasoning in one line.
- UNKNOWN: not checked. Say so and say how to check.

## High-risk claim types (check each before stating)

| Claim | Required evidence |
|---|---|
| File exists / contains X | You opened or searched it |
| Function/API/flag exists | Source, docs, installed package metadata, or compiler acceptance |
| Version number | Manifest, `--version` output, or docs page with version |
| Line number | Read from current file state, not from memory |
| Test passes / build succeeds | Command output with exit status |
| URL or citation | You retrieved it |
| Numeric result | Tool or script output, not mental arithmetic |
| "Fixed" | The original reproduction now passes |

## Procedure

1. Draft the answer.
2. Scan it for specifics from the table above.
3. For each: attach evidence, downgrade to INFERRED/UNKNOWN, or delete it.
4. Remove claims that no longer have support.
5. Add one line listing what was not verified.

## Rules

- Never invent function names, package names, flags, config keys, error codes, file paths, or citations.
- "I don't know" or "I didn't run it" is a correct answer.
- Do not fill gaps with plausible-sounding details.
- When the user's premise looks wrong, say so with evidence instead of building on it.
- Do not claim to remember earlier sessions; rely on STATE.md or MEMORY.md.

## Tools (verification helpers)

- `bt find-symbol -Pattern "X" -Literal` : prove a symbol or file reference exists.
- `bt read-range -Path f -Around N` : prove a line number and its content.
- `bt run-limited -Command "..."` : produce real command output instead of recalled output.
- `bt calc-score` : numbers come from a tool.

For reverse-engineering claims: use `bt re-evidence` (OBS / INF / UNK). Never describe code, functions, or runtime behavior that no tool result showed.
