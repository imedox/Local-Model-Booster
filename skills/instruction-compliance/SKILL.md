---
name: instruction-compliance
display-name: Instruction Compliance
description: Convert user requests into checkable acceptance criteria with explicit prohibitions. Guarantees that all constraints and deliverables are satisfied without scope drift.
---

# Instruction Compliance

## Step 1: Extract

Read the request twice. Tag every requirement:

- M mandatory behavior
- P prohibited behavior
- Q quality/performance objective
- C compatibility requirement
- D deliverable or format (file type, name, language, length, "only X")

Preserve exact values: paths, names, versions, numbers, interface names, output format, language. Follow "do not write text, only the link" style instructions literally.

## Step 2: Checklist

```
ID | Type | Requirement (exact words) | Weight | Evidence that proves it
R1 | M    | ...                       | 3      | test X passes / file Y contains Z
```

Never replace a precise requirement with a vague paraphrase. If two requirements conflict, flag it (clarification-policy) and pick the higher-priority one explicitly.

## Step 3: Hidden requirements

Add implied needs only when clearly implied: builds without errors, existing tests still pass, no data loss, matches project conventions. Mark them "implied".

## Step 4: Scope protection

- Do not remove functionality without authorization.
- Do not rewrite unrelated modules.
- Keep public interfaces unless a change is required and permitted.
- No new dependencies or config changes without need.
- Respect safety and data-preservation rules.

## Step 5: Track

Statuses: not started, implemented-unverified, verified, failed, blocked. "Verified" needs real evidence.

## Step 6: Final audit (mandatory)

1. Re-read the ORIGINAL request, not your plan.
2. Walk the checklist line by line.
3. Check the output format and language against D items.
4. Confirm no P item was violated.
5. Report unmet items, limits, and open questions explicitly.

## Done when

Every mandatory item is implemented and verified or has a documented blocker, and no prohibited action occurred.
