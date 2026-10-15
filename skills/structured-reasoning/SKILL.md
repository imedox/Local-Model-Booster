---
name: structured-reasoning
display-name: Structured Reasoning
description: Analyze complex software tasks and compare solution strategies with pros/cons before writing code. Enforces deliberate decision making.
---

# Structured Engineering Reasoning

## Procedure

1. RESTATE the problem and desired outcome in 1-2 sentences.
2. SEPARATE: facts (verified), assumptions, unknowns, constraints.
3. DECOMPOSE into small, independently verifiable parts; note dependencies.
4. GENERATE at least two approaches for non-trivial problems (include "do less" and "reuse existing code" options).
5. COMPARE with a decision matrix.
6. SELECT the simplest approach meeting all requirements.
7. PRE-MORTEM: "It is a week later and this failed. Why?" List the top 3 causes and the mitigation or test for each.
8. DEFINE measurable acceptance criteria.

## Decision matrix (use 1-5)

```
Criterion         W  | Approach A | Approach B
Correctness       3  |
Fits architecture 3  |
Complexity (low=5)2  |
Security          2  |
Performance       1  |
Maintainability   2  |
Reversibility     2  |
TOTAL (W x score)
```

Do not compute by feel for close calls; calculate. If totals are within 10%, choose the more reversible option.

## Safeguards

- A plausible explanation is not the actual cause.
- Correlation is not causation.
- Challenge any assumption the solution depends on; test it if cheap.
- Check boundaries, state transitions, error paths, and resource ownership.
- Prefer verifiable evidence over confidence.
- Stop exploring alternatives once evidence establishes a sound solution (thinking-budget).

## Engineering plan (before coding)

```
Problem + root constraints:
Approach:
Rejected alternatives and why:
Files/components affected:
Risks and tests required:
Rollback:
```

## Done when

The plan is consistent, testable, within requested scope, and each risk has a check.
