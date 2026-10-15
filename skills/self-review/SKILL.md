---
name: self-review
display-name: Self Review
description: Critically review generated code and plans before presenting them. Challenges assumptions, checks diffs for accidental edits, and spots edge cases.
---

# Independent Self-Review

## Principle

The first implementation is a candidate, not a proven solution. Review it as if someone else wrote it and you are paid to find faults.

## Pass 1: Requirements and diff

1. Re-read the original requirements (not just your plan).
2. View the actual diff and affected code paths.
3. Walk the acceptance checklist; mark each item pass / fail / unverified.

## Pass 2: Defect lenses (check one lens at a time)

| Lens | Questions |
|---|---|
| Logic | boundary values, empty/null, off-by-one, wrong operator, state transitions |
| Errors | swallowed exceptions, misleading messages, partial failure cleanup |
| Resources | files/streams/handles disposed, subscriptions removed, unbounded growth |
| Concurrency | races, deadlocks, UI-thread access, async misuse |
| Security | untrusted input reaching shell/SQL/paths (security-review) |
| Compatibility | versions, platforms, public API breaks |
| Performance | accidental O(n^2), repeated I/O, blocking calls |
| Tests | do they hit the changed branches, do they fail when the code is wrong |

## Counterexample hunt

Write 3 inputs that could break the code (empty, huge, malformed, concurrent, unusual encoding). Run them if possible; otherwise trace by hand and label as unverified.

## Evidence discipline

For each suspected defect record: code involved, trigger scenario, why it is wrong, evidence, proposed fix, regression test. Do not invent vulnerabilities or claim unobserved failures were observed.

## Fix and re-check

Fix only substantiated defects. Re-run relevant checks. Maximum 2 full review passes; further passes only if a high-impact defect was found in pass 2.

## Stop when

All acceptance criteria pass, no unresolved high-impact defect has evidence, and further changes lack concrete justification.

## Output

Verified defects, corrected defects, remaining risks, checks not performed (and why).

## Tools

- `bt diff-summary` : actual diff stat, whitespace problems, untracked files.
- `bt find-leftovers` : stubs and TODOs left in code.
- `bt run-checks` : build and tests before claiming anything.
- `bt secret-scan` : quick leak check.
