---
name: re-evidence-discipline
display-name: RE Evidence Discipline
description: Separate observations, inferences, and unknowns in reverse-engineering. Forbids describing binary behavior not directly confirmed by disassembly or decompilation.
---

# RE Evidence Discipline

## Three kinds of statements

| Kind | Meaning | Needs |
|---|---|---|
| OBS | Read directly from a tool result or file | source (tool, file, offset, address) |
| INF | Reasoned from observations | basis (evidence IDs) |
| UNK | Not established | what would resolve it |

## Procedure

1. After each meaningful tool result: `bt re-evidence -Kind OBS -Claim "..." -Source "re-triage app.exe: imports WinHttpOpen" -Confidence high`.
2. When you conclude something: `bt re-evidence -Kind INF -Claim "..." -Basis "E1,E3" -Confidence medium` (refused if a basis ID does not exist).
3. When something cannot be established: `bt re-evidence -Kind UNK -Claim "..."`.
4. Before the report: `bt re-evidence -Show`; every claim in the report must map to an ID.

## Rules

- Static analysis never shows execution. Never write "the app does X at runtime" without runtime evidence.
- Strings, imports, and symbol names suggest behavior; they do not prove it.
- Keep limitations: packing, obfuscation, partial coverage, tool version, provider used.
- Redact secrets: log that a credential-like string exists and where, never its value.
- Do not repeat identical tool calls; reuse the logged result.
- A reconstruction (rebuilt code) is a design choice backed by observations; say which parts were observed and which are your choices.

## Report template

```
Target / mode (with-ida | without-ida) / tools and versions:
Findings: <claim> [E#]
Inferences: <claim> (basis E#, confidence)
Unknowns and how to resolve them:
Limitations: packing, coverage, static-only
```
