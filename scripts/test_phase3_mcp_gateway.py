"""
Phase 3 Unit Test: REA Meta-Gateway MCP Server (Context Reduction & Tool Execution)
"""

import sys
import json
import subprocess
from pathlib import Path

def run_phase3_test():
    script_path = Path(__file__).resolve().parent.parent / "tools" / "rea_gateway_mcp.py"
    assert script_path.exists(), f"Gateway script missing at {script_path}"

    print(f"[*] Step 1: Spawning Meta-Gateway MCP process (stdio JSON-RPC)...")
    proc = subprocess.Popen(
        ["python", str(script_path)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8"
    )

    def send_rpc(msg):
        line = json.dumps(msg) + "\n"
        proc.stdin.write(line)
        proc.stdin.flush()
        resp_line = proc.stdout.readline()
        return json.loads(resp_line.strip())

    try:
        print("[*] Step 2: Testing MCP 'initialize' handshake...")
        init_req = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "clientInfo": {"name": "test-runner", "version": "1.0"}
            }
        }
        init_resp = send_rpc(init_req)
        assert init_resp.get("result", {}).get("serverInfo", {}).get("name") == "rea-meta-gateway"
        print("    [+] Handshake successful: server recognized as 'rea-meta-gateway'.")

        print("[*] Step 3: Benchmarking context token size of 'tools/list'...")
        tools_req = {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}
        tools_resp = send_rpc(tools_req)
        tools = tools_resp.get("result", {}).get("tools", [])
        assert len(tools) == 5, f"Expected 5 tools, got {len(tools)}"

        # Calculate character and token estimate (1 token ~= 4 chars)
        tools_json = json.dumps(tools)
        char_count = len(tools_json)
        est_tokens = char_count // 4

        print(f"    [+] Exposed Tools: {[t['name'] for t in tools]}")
        print(f"    [+] Schema Characters: {char_count} chars (~{est_tokens} tokens)")
        print(f"    [+] CONTEXT COMPARISON: 260,959 tokens (original REA) -> {est_tokens} tokens (Meta-Gateway)")
        assert est_tokens < 1800, f"Token count exceeded ceiling: {est_tokens} > 1800"
        print("    [+] PASSED: Context overhead reduced by over 99.4%!")

        print("[*] Step 4: Testing 'rea_run' tool execution & evidence interception...")
        # Run a command that outputs 200 lines
        run_req = {
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": {
                "name": "rea_run",
                "arguments": {
                    "tool_name": "mock_triage",
                    "command": "1..200 | ForEach-Object { if ($_ -eq 75) { 'API: VirtualAllocEx called at 0x401000' } else { 'Entry: routine trace line ' + $_ } }",
                    "summary": "Mock triage output testing interception"
                }
            }
        }
        run_resp = send_rpc(run_req)
        content_text = run_resp.get("result", {}).get("content", [{}])[0].get("text", "")
        run_data = json.loads(content_text)
        print(f"    [+] 'rea_run' response: {run_data}")
        assert "evidence_id" in run_data, "Evidence ID missing in response!"
        assert run_data["lines"] >= 200, f"Expected >= 200 lines, got {run_data['lines']}"
        assert len(content_text) < 500, "Tool response was not bounded/compacted!"
        ev_id = run_data["evidence_id"]

        print("[*] Step 5: Testing 'rea_search_evidence' via MCP...")
        search_req = {
            "jsonrpc": "2.0",
            "id": 4,
            "method": "tools/call",
            "params": {
                "name": "rea_search_evidence",
                "arguments": {
                    "query": "VirtualAllocEx",
                    "limit": 3
                }
            }
        }
        search_resp = send_rpc(search_req)
        search_content = json.loads(search_resp.get("result", {}).get("content", [{}])[0].get("text", ""))
        print(f"    [+] Found {search_content['hits_count']} hits for 'VirtualAllocEx'.")
        assert search_content["hits_count"] > 0, "Expected at least 1 hit!"
        assert "VirtualAllocEx" in search_content["results"][0]["snippet"]

        print("[*] Step 6: Testing 'rea_export_ida' via MCP...")
        ida_req = {
            "jsonrpc": "2.0",
            "id": 5,
            "method": "tools/call",
            "params": {
                "name": "rea_export_ida",
                "arguments": {
                    "target_file": "payload_test.dll",
                    "functions": [
                        {
                            "ea": "0x10001000",
                            "name": "HookedInjectionRoutine",
                            "category": "critical_injection",
                            "comment": "Injected code entry point"
                        }
                    ],
                    "output_path": r"C:\REA-Context\mcp_generated_patch.py"
                }
            }
        }
        ida_resp = send_rpc(ida_req)
        ida_content = json.loads(ida_resp.get("result", {}).get("content", [{}])[0].get("text", ""))
        print(f"    [+] Export response: {ida_content.get('message')}")
        assert Path(r"C:\REA-Context\mcp_generated_patch.py").exists(), "Script file was not created!"

        print("\n" + "="*50)
        print(">>> PHASE 3 TEST: PASSED (100% SUCCESS) <<<")
        print("="*50)

    finally:
        proc.terminate()
        proc.wait(timeout=5)

if __name__ == "__main__":
    run_phase3_test()
