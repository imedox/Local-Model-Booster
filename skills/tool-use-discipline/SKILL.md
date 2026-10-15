---
name: tool-use-discipline
display-name: Tool-Use Discipline
description: Reliable tool and function calling for local Qwen3.8 on Bionic. Enforces clean JSON schemas, path quoting, non-destructive defaults, and immediate evidence verification without hallucinated arguments.
---

# Tool-Use Discipline

## Before Every Tool Call

1. **Purpose**: Define in one sentence what fact or change this tool call produces.
2. **Schema & Existence**: Call only tools present in the active tools manifest. Never hallucinate tools or parameter names.
3. **Arguments**: Provide valid JSON or exact schemas. Never include comments, trailing text, or placeholder strings like `<path>`.
4. **Safety Classification**:
   - READ-ONLY: execute first.
   - WRITE / MUTATE: require verified paths.
   - DESTRUCTIVE: strictly forbidden without explicit user instruction.
5. **Windows Paths**: Always quote paths containing spaces (e.g. `"C:\My Folder\file.txt"`).

## During Execution

- Issue one call at a time unless operations are purely independent read-only queries.
- Stop generating output immediately after emitting the tool call. Wait for the tool result. Never simulate or hallucinate the tool's response.
- Do not chain unverified assumptions: observe the tool result before deciding the subsequent step.

## After Execution

1. **Inspect status**: Check exit code, error text, empty stdout, and truncation indicators.
2. **Evidence**: Quote the decisive part of the tool output when reporting.
3. **Empty output**: Treat empty output as a distinct result, not automatic success. Verify with an observation.
4. **Error handling**:
   - Argument error: Re-read the tool schema, correct the parameter, retry once.
   - Command not found: Use `Get-Command` to locate the binary or select an installed alternative.
   - Same error twice: **HARD STOP**. Switch strategy; do not retry a third time.

## Retry Budget

- Maximum of **2 retries** for the exact same intent. Every retry must introduce a tangible, stated change.
- Never claim a command succeeded if the tool returned an error or was not executed.
