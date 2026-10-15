---
name: long-output-chunking
display-name: Long Output Chunking
description: Produce long files, documents, or multi-part answers without truncation or ellipses. Chunks output systematically across verified sections.
---

# Long Output Chunking

## When to chunk

- File over ~150 lines or ~6 KB of output.
- Several files in one task.
- A previous answer was cut off or began to repeat.

## Procedure

1. OUTLINE: list sections/functions with one line each. Decide public interfaces first.
2. SKELETON: write the file with signatures and `NotImplemented`/stub bodies that compile.
3. FILL: implement one function or section per step.
4. CHECK after each step: syntax/build or a quick run. Fix before continuing.
5. INTEGRATE: wire pieces together; run tests.
6. FINAL READ: view the complete file once; look for duplicates, missing pieces, leftover stubs.

## Rules

- Each chunk must be complete and valid on its own: no "..." and no "continue here".
- Keep names, types, and signatures identical to the outline; update the outline if they change.
- Do not regenerate already verified parts. Edit in place.
- When resuming after truncation: read the end of the file, continue from the last complete line, do not restart.
- Search for leftover markers at the end: `TODO`, `NotImplemented`, `...`, `pass  # stub`.
- Prefer several small files with clear responsibilities over one giant file when the project allows it.

## Long explanations or reports

Write the conclusion first, then sections in priority order, so truncation loses the least important material. Offer to continue instead of compressing quality.

## Tools

- `bt find-leftovers -Path src` : final check for `TODO`, `NotImplemented`, `...`, stubs (exit 1 if any).
- `bt read-range -Path f -Outline` : confirm structure matches the outline.
- `bt run-checks -Kind build` : build after each chunk.
