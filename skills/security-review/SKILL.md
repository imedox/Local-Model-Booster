---
name: security-review
display-name: Security Review
description: Targeted security review of code handling untrusted input, files, subprocesses, auth, or network requests. Checks injection, path traversal, and secrets.
---

# Security Review

## Scope first

Identify trust boundaries: where untrusted data enters (user input, files, network, environment, tool output, web pages) and where it reaches sensitive sinks (shell, SQL, file paths, deserializers, HTML, eval, native memory).

## Checklist (only apply what is relevant)

| Area | Look for |
|---|---|
| Injection | String-built SQL, shell commands, `Process.Start`/`os.system` with user data, template injection |
| Paths | Path traversal (`..`), unvalidated archive extraction (zip-slip), symlink following |
| Deserialization | Unsafe binary/pickle/`TypeNameHandling`, loading untrusted plugins |
| AuthN/AuthZ | Missing checks, client-side-only checks, insecure defaults |
| Secrets | Keys/tokens in code, logs, URLs, config committed to git |
| Crypto | Custom crypto, weak hashes for passwords, fixed IVs, `Random` for secrets |
| Web | XSS, CSRF, open redirect, SSRF, CORS wildcards |
| Resources | Unbounded input size, regex DoS, missing timeouts, unclosed handles |
| Dependencies | Unmaintained or typosquatted packages, unpinned versions, known advisories |
| LLM/agents | Prompt injection via retrieved content, tool over-permission, exfiltration via URLs |

## Procedure

1. List boundaries and sinks (5 lines).
2. Trace each untrusted input to its sink; note validation on the path.
3. Classify findings: CONFIRMED (demonstrable or clear from code), PLAUSIBLE (needs investigation), REJECTED.
4. For confirmed issues: smallest fix + a regression test.
5. Re-scan the fix for new issues.

## Report

```
[SEVERITY] <title> — <file:line>
Evidence: <code or test>
Impact: <what an attacker can do>
Fix: <minimal change>
Status: CONFIRMED | PLAUSIBLE
```

Severity: Critical, High, Medium, Low. Do not invent vulnerabilities; do not call code "secure", only "no issues found in the reviewed scope".

## Tools

- `bt secret-scan -Path .` : masked report of keys, tokens, passwords, private keys, `.env` files (exit 1 if found).
- `bt find-symbol -Pattern "Process.Start|os.system|eval\(|SqlCommand" -Include "*.cs,*.py"` : locate dangerous sinks.
- `bt deps-info` : review declared dependencies.

## Reverse engineering safety

For binaries or apps the user wants analyzed, follow `re-mode-gate` (authorization and mode first). Report analysis of untrusted samples only from static evidence unless the user approves running them in an isolated environment.
