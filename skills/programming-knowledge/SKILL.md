---
name: programming-knowledge
display-name: Programming Knowledge
description: Verify programming languages, APIs, framework versions, and dependencies before writing code. Eliminates hallucinated libraries and incompatible syntax.
---

# Programming Knowledge Verification

## Mandatory rules

1. Inspect the existing codebase before assuming architecture, language version, dependencies, or conventions.
2. Identify exact language, framework, compiler/SDK, and library versions.
3. Never invent an API, method, property, package, CLI option, or config key.
4. Evidence priority: working project code and tests > installed package metadata and local docs > official docs > clearly labelled inference.
5. Offline: use source, package metadata, XML docs, examples, `--help`, and compiler diagnostics.
6. Check compatibility before adding dependencies; prefer what the project already uses.
7. Prefer the simplest implementation that fits the existing architecture.
8. Separate confirmed facts from assumptions.

## Version discovery

| Ecosystem | Commands / files |
|---|---|
| .NET | `dotnet --info`, csproj `TargetFramework`, `PackageReference` versions, `global.json` |
| Python | `py -3 --version`, `pip list`, `pyproject.toml`, `requirements*.txt` |
| Node | `node -v`, `package.json` engines and dependencies, lockfile |
| C/C++ | compiler `--version`, CMake/standard flags |
| Any | lockfiles, CI config, `Dockerfile`, README |

## API verification ladder

1. Find an existing usage in the repo (`rg`). Copy its pattern.
2. Inspect the installed package: XML docs, `pip show`, `node_modules/<pkg>/package.json` and types.
3. Run a tiny isolated snippet or compile check.
4. Read official docs for that version (web-research).
5. If still unverified, say so and write the code defensively.

## Pre-implementation checklist (internal, 5 lines)

- Required API or behavior?
- Which version applies?
- What proves it exists?
- Compatibility constraints?
- What remains uncertain?

## Framework cautions

- UI frameworks (Avalonia, WPF, WinForms): UI-thread affinity, binding and MVVM conventions, disposal of subscriptions and native resources.
- Async code: no `.Result`/`.Wait()` on UI threads; propagate cancellation.
- Python: virtual environments, type hints present in project, no mutable default args.
- Do not mix API generations (for example old and new versions of the same library) in one file.

## When uncertain

Do not fabricate certainty. Inspect more, search docs, or design a small isolated test. Report the uncertainty.

## Done when

The code fits the discovered environment and key assumptions are verified or reported.

## Tools

- `bt env-check` : installed SDK and runtime versions.
- `bt deps-info` : target framework and package versions declared by the project.
- `bt find-symbol -Pattern "Api" -Include "*.cs"` : find an existing usage to copy.
- `bt inspect-dotnet -Assembly <dll> -TypeFilter "*Window*" -Members` : verify a .NET type or member exists (see its note about Framework vs modern .NET loading).
