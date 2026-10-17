"""
Phase 2 Unit Test: IDAPython Annotation & Coloration Generator
"""

import sys
import py_compile
from pathlib import Path

# Add tools to path
tools_dir = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(tools_dir))

from re_ida_export import generate_idapython_script, PALETTE

def run_phase2_test():
    print("[*] Step 1: Preparing realistic sample reverse engineering annotations...")
    mock_annotations = {
        "target_file": "trojan_stealth_dropper.exe",
        "functions": [
            {
                "ea": "0x00401000",
                "name": "loader_init",
                "type": "int __stdcall loader_init(void)",
                "comment": "Safe environment sanity checks and PEB check",
                "category": "safe_routine"
            },
            {
                "ea": "0x004014D2",
                "name": "inject_remote_thread",
                "type": "BOOL __stdcall inject_remote_thread(HANDLE hProcess, BYTE *pCode, SIZE_T sCode)",
                "comment": "CRITICAL: Allocates memory and injects code via VirtualAllocEx / CreateRemoteThread",
                "category": "critical_injection",
                "variables": [
                    {"old_name": "v1", "new_name": "target_hProcess"},
                    {"old_name": "v4", "new_name": "pAllocatedBase"}
                ]
            },
            {
                "ea": "0x00402AB4",
                "name": "crypto_rc4_decrypt",
                "type": "void __cdecl crypto_rc4_decrypt(BYTE *pPayload, DWORD dwLen, BYTE *pKey)",
                "comment": "RC4 decryption loop for packed payload",
                "category": "crypto_obfuscation"
            },
            {
                "ea": "0x004071A0",
                "name": "network_beacon_c2",
                "type": "void __stdcall network_beacon_c2(const char *szServerUrl)",
                "comment": "C2 exfiltration and host check-in beacon",
                "category": "network_c2"
            }
        ],
        "comments": [
            {"ea": "0x004014E0", "text": "Call to VirtualAllocEx with PAGE_EXECUTE_READWRITE", "repeatable": True}
        ]
    }

    print("[*] Step 2: Generating IDAPython script content...")
    script_text = generate_idapython_script(mock_annotations)

    out_path = Path(r"C:\REA-Context\test_ida_patch.py")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(script_text, encoding="utf-8")
    print(f"    [+] Saved generated IDAPython script to {out_path} ({len(script_text)} characters).")

    print("[*] Step 3: Validating Python syntax & bytecode compilation...")
    try:
        py_compile.compile(str(out_path), doraise=True)
        print("    [+] Bytecode compilation successful. Clean Python 3 syntax guaranteed!")
    except Exception as e:
        assert False, f"Syntax error in generated script: {e}"

    print("[*] Step 4: Verifying color coding palette mapping...")
    assert hex(PALETTE["critical_injection"]) in script_text, "Critical injection color missing!"
    assert hex(PALETTE["crypto_obfuscation"]) in script_text, "Crypto color missing!"
    assert hex(PALETTE["network_c2"]) in script_text, "Network C2 color missing!"
    assert hex(PALETTE["safe_routine"]) in script_text, "Safe routine color missing!"
    print(f"    [+] Verified colors: Red={hex(PALETTE['critical_injection'])}, Orange={hex(PALETTE['crypto_obfuscation'])}, Blue={hex(PALETTE['network_c2'])}, Green={hex(PALETTE['safe_routine'])}")

    print("[*] Step 5: Executing mock IDA runtime simulation...")
    class MockIDC:
        CIC_FUNC = 1
        SN_CHECK = 1
        SN_NOWARN = 2
        PT_SILENT = 1
        def set_name(self, ea, name, flags): return True
        def set_color(self, ea, what, color): return True
        def apply_type(self, ea, type_tuple): return True
        def parse_decl(self, decl, flags): return ("parsed", decl)
        def set_func_cmt(self, ea, cmt, rpt): return True
        def set_cmt(self, ea, cmt, rpt): return True

    import types
    mod_idc = types.ModuleType("idc")
    mock_inst = MockIDC()
    mod_idc.CIC_FUNC = 1
    mod_idc.SN_CHECK = 1
    mod_idc.SN_NOWARN = 2
    mod_idc.PT_SILENT = 1
    mod_idc.set_name = mock_inst.set_name
    mod_idc.set_color = mock_inst.set_color
    mod_idc.apply_type = mock_inst.apply_type
    mod_idc.parse_decl = mock_inst.parse_decl
    mod_idc.set_func_cmt = mock_inst.set_func_cmt
    mod_idc.set_cmt = mock_inst.set_cmt

    mod_idaapi = types.ModuleType("idaapi")
    mod_idautils = types.ModuleType("idautils")

    sys.modules["idc"] = mod_idc
    sys.modules["idaapi"] = mod_idaapi
    sys.modules["idautils"] = mod_idautils

    sandbox_globals = {
        "__builtins__": __builtins__,
        "print": lambda *args: None
    }

    try:
        exec(script_text, sandbox_globals)
        renamed = sandbox_globals.get("renamed_count", 0)
        colored = sandbox_globals.get("colored_count", 0)
        typed = sandbox_globals.get("typed_count", 0)
        commented = sandbox_globals.get("commented_count", 0)
        print(f"    [+] IDA simulation passed cleanly:")
        print(f"        - Functions renamed: {renamed}/4")
        print(f"        - Functions colored: {colored}/4")
        print(f"        - Types applied:     {typed}/4")
        print(f"        - Comments applied:  {commented}/5")
        assert renamed == 4, f"Expected 4 renamed, got {renamed}"
        assert colored == 4, f"Expected 4 colored, got {colored}"
        assert typed == 4, f"Expected 4 typed, got {typed}"
        assert commented == 5, f"Expected 5 commented, got {commented}"
    except Exception as e:
        assert False, f"Mock IDA runtime execution failed: {e}"

    print("\n" + "="*50)
    print(">>> PHASE 2 TEST: PASSED (100% SUCCESS) <<<")
    print("="*50)

if __name__ == "__main__":
    run_phase2_test()
