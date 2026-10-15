---
name: systematic-debugging
display-name: Systematic Debugging
description: Reproduce defects, formulate competing hypotheses, isolate root causes with evidence, and apply minimal verified fixes. Avoids speculative edits.
---

# Systematic Debugging

## Sequence

1. REPRODUCE. Run the failing scenario. If impossible, state exactly what evidence is missing.
2. RECORD: exact input, expected, actual, full error text, environment/version.
3. MINIMIZE: shrink to the smallest input, test, or code path that still fails.
4. TRACE the execution path and state changes near the failure (read real code, not memory).
5. HYPOTHESES: list 2-4 plausible root causes in a table.
6. DISCRIMINATE: for each, define an observation that would confirm or kill it (log line, print, assertion, debugger, unit test, bisect).
7. COLLECT evidence; eliminate hypotheses; select the cause supported by evidence.
8. FIX the root cause with the smallest justified change.
9. RE-RUN the original reproduction, then related regression tests.
10. DIFF: inspect for unintended changes.

## Hypothesis table

```
# | Hypothesis | Predicts | Test | Result
1 | ...        | ...      | ...  | confirmed / refuted / open
```

## Techniques

- Read the first error, not the last; the earliest failure is usually the cause.
- Bisect: `git bisect`, or comment out halves, or binary-search the input.
- Diff working vs failing: versions, config, data, environment.
- Add targeted logging at boundaries; remove it after.
- Check assumptions about types, nullability, encoding, culture, time zones, threading.
- Intermittent failures: look for races, shared state, ordering, timeouts; run the test repeatedly.
- Performance: measure first (profiler or timers); fix the measured hot spot only.

## Rules

- Never claim a root cause because a change "seems plausible".
- Do not suppress exceptions or weaken tests to get green.
- No unrelated refactoring during a bug fix.
- Preserve behavior outside the affected scope.
- Fix attempt number 3 on the same hypothesis is forbidden: apply loop-guard.

## If the fix fails

Preserve logs -> revisit hypotheses -> decide whether test, environment, or implementation is at fault -> change the solution from new evidence -> rerun tests. Revert failed experiments (git-checkpoints).

## Completion report

Defect, supported root cause (with evidence), files changed, tests run and results, remaining uncertainty. Never call a fix verified unless the relevant test ran and passed.

## Tools

- `bt run-limited -Command "<repro>" -TimeoutSec 120` : capture the exact failing output (also saved in `.agent\evidence.log`).
- `bt tail-log -Path app.log -Errors` : first error lines, not the whole log.
- `bt loop-check -Record "<hypothesis + result>"` : stop repeating an attempt.
- `bt git-checkpoint -Action log` and `bt diff-summary` : find recent changes for bisecting.
- `bt find-symbol` : locate the failing code path.
