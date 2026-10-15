# ASAR, JavaScript and Electron apps

1. Locate `resources\app.asar` (and `app.asar.unpacked`). Offline listing: `bt re-asar -Path app.asar -List -Filter "*.js"`.
2. Extract only what is needed: `bt re-asar -Path app.asar -Extract D:\work\app -Filter "*"` (size-capped).
3. Run the module analysis once: REA `analyze_javascript_application` or `bt rea-run -Command analyze-javascript-application -Target <dir-or-asar>`. Read the summary; follow paged resource URIs for the one relevant part.
4. Trace a feature: renderer code -> preload -> IPC channel -> main-process handler -> native add-on. Use `bt find-symbol -Pattern "ipcMain|ipcRenderer|contextBridge|preload" -Include "*.js"` to locate hops.
5. Source maps, if present, are evidence of original names and paths; minified names are not.
6. Version comparison: extract both versions, then `bt re-diff-dirs -Old <v1> -New <v2> -Include "*.js,*.json"`; inspect only changed files.
7. Report: what the code does (observation), what it implies (inference), what depends on server or runtime state (unknown).
