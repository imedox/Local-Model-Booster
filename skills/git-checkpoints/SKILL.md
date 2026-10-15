---
name: git-checkpoints
display-name: Git Checkpoints
description: Use git for safe checkpoints, diff review, and rollback during code changes. Never lose working code during refactoring or complex multi-step edits.
---

# Git Checkpoints

## Start of a task

1. `git status --short` and note unrelated uncommitted changes. Do not touch or commit them.
2. If the repo is clean and a branch is appropriate: `git switch -c agent/<short-task-name>`.
3. If not a git repo: copy the files you will modify to `.agent/backup/` before editing, and say so.

## During work

- Commit after each verified milestone: `git add <specific files>` then `git commit -m "<type>: <what>"`.
- Message format: `fix|feat|refactor|test|docs: short imperative summary`.
- Review before commit: `git diff --stat` then `git diff` on the files.
- Never `git add -A` blindly; avoid committing build output, secrets, or large binaries.

## Recovery

| Situation | Safe action |
|---|---|
| Edit made things worse | `git diff` to inspect, `git restore <file>` for that file only (after confirming it holds only my changes) |
| Need to compare | `git diff <commit> -- <file>` |
| Find which commit broke it | `git bisect` with a reproducible test |
| Lost track | `git log --oneline -n 15` and `git status` |

## Forbidden without explicit user authorization

`git reset --hard`, `git clean -fd`, `git push --force`, `git rebase` of shared history, deleting branches, rewriting published history, committing `.env` or credentials.

## Report

List the branch, commits created, and `git diff --stat` summary.

## Tools

- `bt git-checkpoint -Action status|log|diff` : read-only views.
- `bt git-checkpoint -Action branch -Name fix-login` : creates `agent/fix-login`.
- `bt git-checkpoint -Action commit -Files "a.cs,b.cs" -Message "fix: ..."` : refuses `.`/`*` and secret-looking files.
- `bt git-checkpoint -Action restore -Files "a.cs"` : shows what would be lost; needs `-Yes` after confirmation.
- `bt diff-summary` : review before commit. `bt backup-files` : non-git fallback.
