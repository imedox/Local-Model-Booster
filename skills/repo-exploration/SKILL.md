---
name: repo-exploration
display-name: Repo Exploration
description: Map an unfamiliar or large codebase cheaply and accurately. Locates entry points, architecture layers, and key symbols without flooding context.
---

# Repo Exploration

## Recon sequence (stop as soon as you can answer the task's "where")

1. Root listing, depth 2 (ignore `node_modules`, `bin`, `obj`, `.git`, `venv`, `dist`, `build`).
2. Identity files: README, manifest (`*.csproj`, `*.sln`, `package.json`, `pyproject.toml`, `requirements.txt`, `CMakeLists.txt`, `Cargo.toml`, `go.mod`).
3. Versions: language/SDK/framework versions from the manifest (see programming-knowledge).
4. Entry points: `Program.cs`, `main.*`, `index.*`, `App.*`, startup/DI registration.
5. Build and test commands: scripts, CI files, Makefile, existing test projects.
6. Task-specific search: `rg -n "<symbol or error text>"` then read +/- 30 lines around hits.
7. History hints: `git log --oneline -n 10`, `git status --short`, recent diffs on affected files.
8. Conventions: naming, error handling, logging, DI, MVVM or layering, test style.

## Windows-friendly commands

```
Get-ChildItem -Recurse -Depth 2 -Directory | Select-Object -First 60
Select-String -Path . -Pattern "Symbol" -Recurse -Include *.cs | Select-Object -First 30
rg -n --glob "!{bin,obj,node_modules,.git}" "Symbol"
```

## Repo map (save to `.agent/REPO_MAP.md`, max 40 lines)

```
PROJECT: <name> | LANG: <lang+version> | BUILD: <cmd> | TEST: <cmd>
LAYOUT: <dir -> purpose, 1 line each>
ENTRY: <files>
KEY TYPES: <name -> file:line -> role>
CONVENTIONS: <bullets>
RISKS: <fragile areas, generated code, do-not-touch>
```

## Rules

- Do not modify anything during recon.
- Identify generated files and vendored code; never hand-edit them.
- Locate the existing tests for the area you will change.
- If the repo is huge, map only the subtree relevant to the task and say so.
- Never describe a file you have not opened or searched.

## Tools

- `bt repo-map -Path . -Depth 2 -Out .agent\REPO_MAP.md` : manifests, layout, extensions, entry points, tests, recent commits in one call.
- `bt find-symbol -Pattern "Name" -Include "*.cs" -Context 2` : capped search that ignores bin/obj/node_modules.
- `bt read-range -Path f -Outline` then `-Around <line>` : outline first, then a window.
- `bt deps-info` : declared dependencies and target framework versions.
