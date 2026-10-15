---
name: test-driven-validation
display-name: Test-Driven Validation
description: Validate software changes with automated tests, builds, and analyzers. Requires capturing exact commands and exit codes as proof of correctness.
---

# Test-Driven Validation

## Before implementation

1. Find existing tests, test runners, and build scripts.
2. Write or identify the smallest test that fails for the right reason (red).
3. Define expected behavior before changing code.
4. For bug fixes: the reproduction test must fail before the fix.

## After implementation (strongest relevant first)

1. Focused unit test(s) for the change.
2. Related integration tests.
3. Build/compile with warnings visible.
4. Static analysis, linters, formatters the project already uses.
5. Full regression suite if it is fast enough; otherwise the affected subset and a note.
6. UI or end-to-end checks when practical.

## Common commands

| Ecosystem | Commands |
|---|---|
| .NET | `dotnet build -v minimal`, `dotnet test --filter <name>`, `dotnet format --verify-no-changes` |
| Python | `python -m pytest -x -q path::test`, `python -m ruff check`, `python -m mypy` (if configured) |
| Node | `npm test -- <pattern>`, `npm run lint`, `npx tsc --noEmit` |
| C/C++ | `cmake --build`, `ctest -R <name>`, sanitizers if available |

Use the project's own commands first (check README, CI, scripts).

## Test quality

- Cover success, boundary, and failure cases.
- A test must fail when the code is wrong: temporarily break the logic or assert specific values.
- No tests that only assert "does not throw" unless that is the requirement.
- Deterministic tests: no sleep-based timing, no dependence on test order or network.
- Do not weaken or delete tests to pass.

## Safety

- Read commands before running them.
- Never delete user data or reset environments without authorization.
- Use temp directories and fixtures.
- Keep failure logs.
- Check free VRAM before GPU-using tests on this machine (the local model server shares the GPU).

## Evidence table (required in reports)

```
Check | Command | Exit | Result (passed/failed/not run/inconclusive) | Notes
```

A green build does not prove correct runtime behavior. Flaky test: rerun 3 times, report the rate, investigate; do not silently ignore.

## Done when

Every feasible high-value check ran, failures were investigated, and the report states evidence and limits accurately.

## Tools

- `bt run-checks -Kind all` : detects .NET, Node, or Python, runs build and tests with timeouts, prints the evidence table, appends `.agent\evidence.log`.
- `bt run-checks -Kind test -Filter <name>` : focused test.
- `bt run-limited -Command "<project command>"` : any other check with timeout and output cap.
- `bt gpu-status` : before GPU-using tests.
