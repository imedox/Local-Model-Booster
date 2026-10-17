"""
IDAPython Annotation & Coloration Script Generator
Produces clean, robust .py scripts to import annotations, comments, types, and color codes into IDA Pro 7.x/8.x/9.x.
Part of Local-Model-Booster.
"""

import json
from typing import Dict, Any, List

# BGR Color Palette for IDA Pro (0xBBGGRR)
PALETTE = {
    "critical_injection": 0x3333FF,  # Bright Red
    "crypto_obfuscation": 0x0078FF,  # Vivid Orange
    "network_c2":         0xFF8000,  # Clear Blue
    "safe_routine":       0x33CC33,  # Fresh Green
    "suspicious":         0xCC33CC,  # Purple
    "none":               0xFFFFFF   # Default
}

TEMPLATE_HEADER = '''# ==============================================================================
# IDAPython Automated Annotation & Triage Script
# Generated automatically by Local-Model-Booster & REA Engine
# Apply in IDA Pro via: File -> Script File... (Alt + F7)
# Compatibility: IDA Pro 7.x / 8.x / 9.x (Python 3)
# ==============================================================================

import idaapi
import idc
import idautils

try:
    import ida_hexrays
    HAS_HEXRAYS = ida_hexrays.init_hexrays_plugin()
except Exception:
    HAS_HEXRAYS = False

print("[*] Starting Local-Model-Booster Annotation Import...")

renamed_count = 0
colored_count = 0
typed_count = 0
commented_count = 0
'''

TEMPLATE_FOOTER = '''
print(f"\\n[+] Annotation Import Finished Successfully!")
print(f"    - Functions Renamed:  {renamed_count}")
print(f"    - Functions Colored:  {colored_count}")
print(f"    - Prototypes Applied: {typed_count}")
print(f"    - Comments Applied:   {commented_count}")
'''

def parse_ea(val: Any) -> str:
    if isinstance(val, int):
        return hex(val)
    if isinstance(val, str):
        if val.startswith("0x") or val.startswith("0X"):
            return val
        try:
            return hex(int(val, 16))
        except ValueError:
            return hex(int(val))
    return str(val)

def generate_idapython_script(annotations: Dict[str, Any]) -> str:
    """
    Transforms structured annotation JSON into an executable IDAPython script.
    """
    code = [TEMPLATE_HEADER]

    target = annotations.get("target_file", "binary")
    code.append(f'# Target Analyzed: {target}\n')

    # 1. Process Functions
    functions = annotations.get("functions", [])
    if functions:
        code.append("# --- Function Renaming, Typing & Color Coding ---")
        for fn in functions:
            ea_str = parse_ea(fn.get("ea", 0))
            name = fn.get("name")
            category = fn.get("category", "none").lower()
            proto = fn.get("type")
            comment = fn.get("comment")
            color = PALETTE.get(category, PALETTE["none"])

            code.append(f"\nea = {ea_str}")
            if name:
                code.append(f'if idc.set_name(ea, "{name}", idc.SN_CHECK | idc.SN_NOWARN):')
                code.append('    renamed_count += 1')

            if color != PALETTE["none"]:
                code.append(f'idc.set_color(ea, idc.CIC_FUNC, {hex(color)})')
                code.append('colored_count += 1')

            if proto:
                clean_proto = proto.replace('"', '\\"')
                code.append(f'if idc.apply_type(ea, idc.parse_decl("{clean_proto};", idc.PT_SILENT)):')
                code.append('    typed_count += 1')

            if comment:
                clean_comment = comment.replace('"', '\\"').replace('\n', ' ')
                code.append(f'idc.set_func_cmt(ea, "{clean_comment}", 1)')
                code.append('commented_count += 1')

            # Optional Hex-Rays variable renaming
            variables = fn.get("variables", [])
            if variables:
                code.append('if HAS_HEXRAYS:')
                code.append('    try:')
                code.append('        cfunc = ida_hexrays.decompile(ea)')
                code.append('        if cfunc:')
                for v in variables:
                    old_v = v.get("old_name")
                    new_v = v.get("new_name")
                    if old_v and new_v:
                        code.append(f'            for lvar in cfunc.get_lvars():')
                        code.append(f'                if lvar.name == "{old_v}":')
                        code.append(f'                    cfunc.rename_lvar(lvar, "{new_v}", 1)')
                        code.append(f'            cfunc.save_user_cmts()')
                code.append('    except Exception as e:')
                code.append('        pass')

    # 2. Process Individual Comments
    comments = annotations.get("comments", [])
    if comments:
        code.append("\n# --- Instruction & Disassembly Comments ---")
        for c in comments:
            ea_str = parse_ea(c.get("ea", 0))
            txt = c.get("text", "").replace('"', '\\"').replace('\n', ' ')
            repeatable = 1 if c.get("repeatable", True) else 0
            code.append(f'idc.set_cmt({ea_str}, "{txt}", {repeatable})')
            code.append('commented_count += 1')

    code.append(TEMPLATE_FOOTER)
    return "\n".join(code)
