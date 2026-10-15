#!/usr/bin/env python3
"""Validate Model-Booster skills: frontmatter, name==folder, description length, size."""
import pathlib, re, sys

root = pathlib.Path(__file__).resolve().parent.parent / "skills"
errors, rows = [], []
for d in sorted(p for p in root.iterdir() if p.is_dir()):
    f = d / "SKILL.md"
    if not f.exists():
        errors.append(f"{d.name}: missing SKILL.md"); continue
    text = f.read_text(encoding="utf-8").replace("\r\n", "\n")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        errors.append(f"{d.name}: bad frontmatter"); continue
    fm = dict(re.findall(r"^(\w[\w-]*):\s*(.+)$", m.group(1), re.M))
    if fm.get("name") != d.name: errors.append(f"{d.name}: name mismatch ({fm.get('name')})")
    desc = fm.get("description", "")
    if not (40 <= len(desc) <= 1024): errors.append(f"{d.name}: description length {len(desc)}")
    allowed_keys = {"name", "display-name", "description", "disable-model-invocation", "user-invocable"}
    if set(fm) - allowed_keys: errors.append(f"{d.name}: extra frontmatter keys ({set(fm) - allowed_keys})")
    if not (d / "diagram.mmd").exists(): errors.append(f"{d.name}: missing diagram.mmd")
    rows.append((d.name, len(text), len(text.splitlines())))
for n, c, l in rows: print(f"{n:28} {c:6} chars {l:4} lines")
tools = {t.stem for t in (root.parent / "tools").glob("*.ps1")}
for d in sorted(p for p in root.iterdir() if p.is_dir()):
    txt = (d / "SKILL.md").read_text(encoding="utf-8")
    for t in set(re.findall(r"bt (?:run-limited|[a-z][a-z-]+)", txt)):
        name = t.split()[1]
        if name not in tools and name not in ("list", "help", "install", "tool", "name", "is", "the", "or", "and"):
            errors.append(f"{d.name}: references unknown tool '{name}'")
print(f"\n{len(rows)} skills, {sum(r[1] for r in rows)} chars")
if errors:
    print("\nERRORS:"); [print(" -", e) for e in errors]; sys.exit(1)
print("OK")
