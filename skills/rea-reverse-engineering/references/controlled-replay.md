# Controlled JavaScript replay

- Replay executes recovered JavaScript in a controlled setting. It runs code: obtain explicit user approval and state what will run and with which inputs.
- Use isolated working directories, no real credentials, no network unless the user approves a specific host.
- Compare replay output with static expectations; any difference is a finding, not an error to hide.
- Stop on unexpected side effects (file writes, process spawns, network) and report them.
