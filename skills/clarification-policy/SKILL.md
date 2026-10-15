---
name: clarification-policy
display-name: Clarification Policy
description: Decide when to ask user questions vs when to proceed with reasonable defaults. Minimizes unnecessary interruptions while protecting against destructive actions.
---

# Clarification Policy

## Decision rule

Ask only if ALL are true:

1. The answer changes the outcome materially.
2. It cannot be found in the repo, config, docs, or conversation.
3. A wrong guess would be costly or hard to reverse.

Otherwise: choose the most reasonable default, state it in one line, and proceed.

## Always ask (or stop) before

- deleting or overwriting user data
- destructive git or database operations
- spending money, sending messages, publishing, or touching production
- changing security settings or credentials
- choosing between two interpretations that lead to totally different deliverables
- ANY reverse-engineering request: always ask WITH IDA Pro MCP or WITHOUT IDA, and confirm authorization (re-mode-gate). This applies in agent-auto too; there is no default.

## Question format

- Maximum 3 questions, ideally 1.
- Each with a recommended default: "Should X use A (recommended) or B?"
- Short, answerable in a few words.
- Ask once, at the start, not repeatedly during execution.

## While waiting

Continue with safe, reversible work that does not depend on the answer.

## Assumption statement (use when proceeding)

```
Assumption: <what> (because <evidence>). Tell me if wrong.
```

## Do not

- Ask what the codebase already answers.
- Ask permission for routine reversible steps.
- Ask open-ended questions such as "what do you want?".
