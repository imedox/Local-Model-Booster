---
name: function-quality-score
display-name: Function Quality Score
description: Independently scores newly written or modified functions across 8 dimensions (correctness, types, error handling, performance). Caps score if critical defects exist.
---

# Function Quality Scoring

## Mission

Act as an independent auditor. Do not award high scores because the code looks plausible, compiles, or was written by you. Every score needs evidence or an explicit uncertainty label.

## Modes

- QUICK (function under ~15 lines, no I/O, no security surface): one-line score with the main reason. Use the 3 most relevant criteria.
- FULL (everything else): all eight criteria and the full report.

## 1. Scope

For each changed function: purpose, original requirement, body, callers, related types, ownership and error conventions, available tests and diagnostics. Evaluate in context. Do not claim the whole application is safe from one function.

## 2. Criteria (score each 0-10)

| | Criterion | Weight | Check |
|---|---|---|---|
| A | Logical correctness | 25 | conditions, off-by-one, missing cases, wrong returns, demonstrated bugs |
| B | Requirement fulfillment | 20 | does the requested thing, preserves old behavior, no needless side effects |
| C | Security | 15 | trust boundaries, injection, authz, secrets, unsafe file/deserialization ops |
| D | Reliability | 15 | null/empty/boundary input, exceptions, cancellation, concurrency, determinism |
| E | Resources and memory | 7 | unclosed handles, leaks, event subscriptions, unbounded buffers, disposal |
| F | Performance | 7 | complexity, repeated expensive work, blocking calls, unsupported claims |
| G | Maintainability | 8 | naming, responsibilities, duplication, conventions, diagnostics |
| H | Simplicity | 3 | unnecessary complexity, oversized function; do not reward brevity itself |

10 requires strong evidence across edge cases. Distinguish confirmed defects from plausible risks. Do not invent vulnerabilities. Do not penalize necessary complexity or normal allocation.

Language lenses: C#/.NET (IDisposable, async/await, UI thread, nullable refs, LINQ in hot paths); Python (mutable defaults, context managers, exceptions); C/C++ (ownership, bounds, RAII); JS/TS (promises, null/undefined, injection).

## 3. Calculation

```
FinalRaw = sum(weight * score) / 100     (one decimal)
```

## 4. Caps (apply the lowest that is CONFIRMED)

- Does not compile in target context: max 4
- Confirmed critical security vulnerability: max 2
- Confirmed severe leak or operational failure: max 4
- Core requested behavior absent or wrong: max 4

Report raw and capped scores separately. Unconfirmed suspicions get documented and investigated, not capped.

## 5. Verification ladder

Compiler/build -> existing tests -> focused unit tests -> boundary and negative tests -> static/security analysis -> resource-lifetime inspection -> profiling (if performance matters) -> manual inspection. Never claim a command ran or a test passed if unknown. A successful build does not prove runtime correctness.

## 6. Challenge pass

Challenge the highest criteria; look for counterexamples; check that tests exercise important branches; check error handling is not hiding failures; rescore if evidence changes.

## 7. Revision loop (score < 8.0)

List up to 3 highest-impact improvements -> fix confirmed defects -> rerun tests -> rescore with the same rubric -> compare. One revision round by default; stop if remaining weaknesses are environmental. Do not rewrite working code only to raise a number; never weaken tests to raise a score.

## 8. Report

```
Function: name @ file:line
Purpose:
Scores: A_ B_ C_ D_ E_ F_ G_ H_
Raw: x.x | Cap: none/reason | Final: x/10
Confirmed defects (evidence):
Unverified risks / missing tests:
Recommended changes:
Checks run:
Confidence: high|medium|low (why)
```

Concise for simple functions; detailed for security-critical or complex ones.

## Tools

- `bt calc-score -Scores "A=..,B=..,C=..,D=..,E=..,F=..,G=..,H=.." [-Cap n]` : exact weighted score and capped final.
- `bt run-checks -Filter <name>` : evidence for criteria A, B, D.
- `bt find-symbol` : callers and usages for context.
