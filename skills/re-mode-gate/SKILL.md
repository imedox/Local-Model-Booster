---
name: re-mode-gate
display-name: RE Mode Gate
description: MANDATORY gate for reverse-engineering tasks. Asks user to choose WITH IDA Pro MCP or WITHOUT IDA and confirms authorization before running any analysis.
---

# RE Mode Gate (ask first, every time)

## Rule

Reverse-engineering work never starts until the user has chosen the mode and confirmed authorization in the CURRENT request. Autonomy (agent-auto), earlier answers, and "obvious" defaults do not replace this question.

## Protocol

1. START of every new reverse-engineering request: run `bt re-mode -Clear`.
2. OPTIONAL context for the question (read-only): `bt rea-doctor` to see whether IDA, ida-pro-mcp, Ghidra, Java, and Node are detected.
3. ASK the user (use an options tool if one exists, otherwise plain text), exactly these two things:

```
Reverse engineering mode?
  1) WITH IDA Pro MCP  - needs your licensed IDA + ida-pro-mcp configured; deepest native analysis
  2) WITHOUT IDA       - REA built-in analyzers (JavaScript/Electron, .NET, APK, archives, websites),
                         Ghidra/Hopper through REA, or offline PowerShell triage tools
Do you own this software or have authorization to analyze it? (yes/no)
```

4. WAIT. Do not run analysis tools, do not open the target, do not guess.
5. If the user's current message already states both the mode and the authorization explicitly, accept it as the answer and skip the question.
6. RECORD the answer: `bt re-mode -Set with-ida -Authorized yes` or `bt re-mode -Set without-ida -Authorized yes`.
7. ROUTE: with-ida -> `re-with-ida`; without-ida -> `re-without-ida`; then `rea-reverse-engineering` and `re-evidence-discipline`.

## If authorization is "no" or unclear

Stop. Explain that analysis is limited to software the user owns or is authorized to examine (research, interoperability, preservation, security work with permission). Do not help with license or key bypass, cracking, malware development, or evasion. Offer lawful alternatives: analyze their own code, read public documentation, or analyze a sample in an isolated environment with permission.

## Legal Disclaimer & End-User Responsibility

As standard in open-source developer tooling, the end-user/operator is solely and legally responsible for compliance with applicable copyright, licensing, and cyber legislation. When the user confirms ownership ("yes, I own/created this software") or authorized security research, the user acts under their own legal responsibility.

## If the mode must change later

If IDA fails or is unavailable, tell the user and ask again whether to switch to without-ida. Never switch silently. Changing the mode means `bt re-mode -Clear` and the question again.

## Enforcement

The `re-*` and `rea-*` tools refuse to run (exit code 5, "RE MODE NOT SET") until the mode is recorded. Treat exit code 5 as: stop and ask the user.

