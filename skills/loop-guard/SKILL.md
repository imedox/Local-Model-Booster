---
name: loop-guard
display-name: Loop Guard
description: Detect and break loops, repetition, and stalled progress. Applies strict in-memory thresholds to prevent circular thinking, revert wars, and duplicate tool calls without relying on slow external scripts.
---

# Loop Guard (In-Memory Protection)

## Detect Signals (Evaluate internally after every action)

| Signal | Threshold | Action |
|---|---|---|
| Identical tool call and parameters | 2 occurrences | **HARD STOP** |
| Same error message after an attempted fix | 2 occurrences | **HARD STOP** |
| Repeated sentence or paragraph in output | 1 occurrence | Truncate and conclude |
| Edit that undoes a previous edit | 1 occurrence | **HARD STOP** |
| Reasoning restating the exact same conclusion | 2 occurrences | Force decision |
| No new file change, test result, or evidence | 3 consecutive actions | Switch strategy |

*Crucial rule*: Perform this detection **in-memory**. Do not run external shell commands or scripts just to evaluate your own repetition. Spawning shell commands to monitor thinking creates latency and secondary loops.

## Break the Loop (Strict 4-Step Sequence)

1. **STOP immediately**: Do not make the same tool call again.
2. **RECORD 3 LINES**:
   - What was attempted:
   - What actually occurred:
   - What is known with 100% certainty:
3. **DIAGNOSE the flawed assumption**: Name the exact premise that proved false.
4. **SWITCH strategy entirely**:
   - Narrow the scope (isolate a single function or test file).
   - Inspect directly instead of guessing (print debug info, read exact line range).
   - Re-read API or framework documentation.
   - Revert to the last clean working checkpoint.

## Strategy Limits

- Allow at most **3 distinct strategies** for any single obstacle.
- After 3 failed strategies: stop, present the verified evidence to the user, and request guidance or clarification. Never keep looping blindly.

## Repetition & Degeneration

If generation starts repeating tokens or phrases, end the output immediately at the last clean sentence. State what was completed and what remains.
