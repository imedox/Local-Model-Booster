---
name: precise-code-editing
display-name: Precise Code Editing
description: Make safe, minimal, verifiable code edits. Prevents truncated files, placeholder comments, whole-file rewrites, wrong anchors, and unverified changes.
---

# Precise Code Editing

## Edit protocol

1. READ the exact region you will change (and its callers if signature changes).
2. DECIDE the smallest change that satisfies the requirement.
3. ANCHOR: choose a unique snippet of existing text for replace-style edits. If the snippet appears more than once, include more context.
4. APPLY one logical change per edit call.
5. RE-READ the edited region to confirm it is exactly what you intended.
6. CHECK: syntax/build/test for the affected file or project.
7. DIFF: view the final diff; remove accidental changes (whitespace storms, reordered usings/imports, changed line endings).

## Rules

- Never output "...", "rest of file unchanged", or "TODO: implement" inside real code.
- Never rewrite a whole file when a targeted edit works. If a rewrite is truly needed, write the complete file.
- Preserve the file's style: indentation, brace style, naming, quote style, line endings (CRLF vs LF), encoding (UTF-8 BOM or not).
- Keep public signatures stable unless required and permitted. If changed, update every caller.
- Add imports/usings only for symbols you actually use; verify the symbol exists (programming-knowledge).
- Do not add dependencies without need (see programming-knowledge).
- Keep comments for the "why", not for restating code.
- Do not delete code you do not understand; search for its usages first.
- For generated or vendored files, change the source or generator instead.
- Handle errors explicitly; do not swallow exceptions to silence failures.

## Multi-file changes

Order: types/interfaces -> implementations -> callers -> tests -> docs. Build after each group if the build is fast.

## Failure handling

If an edit fails to apply: re-read the file (it may have changed), recompute the anchor, retry once. If it fails again, stop and apply loop-guard.

## Done when

The diff contains only intended changes, the project builds, and the relevant tests pass or their absence is stated.

## Tools

- `bt read-range -Path f -Around <line> -Lines 60` : read before and re-read after each edit.
- `bt backup-files -Files "a.cs,b.cs"` : copy to `.agent\backup\` when not in git.
- `bt line-endings -Path src` : detect CRLF/LF/MIXED and BOM before editing; convert only if asked (`-Fix CRLF`).
- `bt diff-summary` : stat, whitespace check, untracked files, large-diff warning.
- `bt find-leftovers` : catch stubs, TODOs, and placeholder ellipses after editing.
