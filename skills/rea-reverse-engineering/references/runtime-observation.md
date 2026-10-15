# Passive runtime observation (browser and Electron)

- Only user-owned pages and apps that the user already opened. Start with `list_browser_targets` or `list_electron_targets`.
- Prefer passive observation: network metadata, loaded scripts, DOM structure, console output. Ask for approval before anything that interacts with or alters the target.
- Reconcile with static results: match observed requests and loaded scripts to modules and routes found statically. Differences go in the unknowns list.
- Do not record or print credentials, cookies, or tokens; note that they exist and where.
- Saved captures (HAR/SAZ) are evidence files: analyze them offline rather than re-running the target.
