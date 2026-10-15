# Native binaries, managed assemblies, archives

## Native (PE/ELF/Mach-O)
1. Offline first (no engine needed): `bt re-triage -Path <file>` for type, hashes, PE headers, sections, entropy, imports, signature. Note packing indicators.
2. `bt re-strings -Path <file> -Preset url` (also path, ip, registry, cmd, key). Strings are observations of bytes, not proof of execution.
3. Deep analysis needs an engine selected by the mode: with-ida uses the user's IDA through REA; without-ida uses Ghidra or Hopper through REA.
4. Open once (`open_binary`, provider id as per mode), read `binary_overview`, then ask for specific functions, references, or strings. Close with `close_binary`.
5. Large binaries: raise the provider startup deadline (`REA_GHIDRA_STARTUP_TIMEOUT_MS` or `REA_HOPPER_STARTUP_TIMEOUT_MS`).

## Managed (.NET)
- Static only. REA inspects metadata and CIL; offline `bt re-triage` flags the CLR header and `bt inspect-dotnet` lists public types.
- Obfuscated assemblies: report renamed or encrypted symbols as a limitation.

## Archives and packages
- `bt re-archive -Path <file>` lists entries safely and flags APK/MSIX/JAR/Electron.
- APK decompilation needs headless JADX and a full JDK; resources need Apktool. Report missing tools instead of guessing.
- Extract only needed entries (`-Filter`, `-Extract`); extraction is size-capped and traversal-safe.

## Always
Record each finding with `bt re-evidence`. Do not describe code you did not read.
