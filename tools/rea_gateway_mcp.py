"""
REA Meta-Gateway MCP Server
Transforms 207 raw REA tools (~260k tokens) into 5 high-speed, surgical meta-tools (~1,200 tokens).
Intercepts raw dumps and routes them into the NVMe SQLite FTS5 Evidence Store.
Part of Local-Model-Booster.
"""

import sys
import os
import json
import subprocess
from pathlib import Path

# Add current tools directory to sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from rea_evidence_db import REAEvidenceStore
from re_ida_export import generate_idapython_script

# Global active store instance
CURRENT_SESSION = os.environ.get("REA_SESSION_ID", "default_session")
evidence_store = REAEvidenceStore(session_id=CURRENT_SESSION)

TOOLS_DEFINITIONS = [
    {
        "name": "rea_catalog",
        "description": "Lists and searches available reverse engineering capabilities, modules, and built-in CLI commands.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "filter": {
                    "type": "string",
                    "description": "Optional keyword to filter capabilities (e.g. 'pe', 'strings', 'ida', 'decompile', 'triage', 'entropy')"
                }
            }
        }
    },
    {
        "name": "rea_run",
        "description": "Executes a reverse engineering command or tool, automatically intercepts large output, archives it to NVMe disk, indexes text in SQLite FTS5, and returns a surgical summary (< 150 tokens) with an Evidence ID.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "tool_name": {
                    "type": "string",
                    "description": "Name or identifier of the tool being run (e.g., 're-triage', 're-strings', 'decompile')"
                },
                "command": {
                    "type": "string",
                    "description": "Shell command or script to execute (e.g., 'bt re-triage target.exe' or 'bt re-strings target.exe')"
                },
                "summary": {
                    "type": "string",
                    "description": "Optional brief statement of purpose for indexing"
                },
                "cwd": {
                    "type": "string",
                    "description": "Optional working directory for the command (defaults to current working directory)"
                }
            },
            "required": ["tool_name", "command"]
        }
    },
    {
        "name": "rea_search_evidence",
        "description": "Performs sub-millisecond full-text search across all indexed reverse engineering findings, decompilations, and dumps in the NVMe SQLite FTS5 store.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search term, API name, symbol, or string (e.g. 'VirtualAlloc', 'rc4', 'http', 'CreateRemoteThread')"
                },
                "limit": {
                    "type": "integer",
                    "description": "Maximum number of snippet hits to return (default: 5)"
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "rea_read_chunk",
        "description": "Surgically inspects a specific line range from an archived Evidence ID (capped to prevent context bloat).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "evidence_id": {
                    "type": "string",
                    "description": "Evidence ID (e.g. 'EV-0001')"
                },
                "offset": {
                    "type": "integer",
                    "description": "Starting line number (0-indexed, default: 0)"
                },
                "count": {
                    "type": "integer",
                    "description": "Number of lines to read (max: 100, default: 40)"
                }
            },
            "required": ["evidence_id"]
        }
    },
    {
        "name": "rea_export_ida",
        "description": "Generates a complete, color-coded IDAPython (.py) script from structured annotations, ready to import in IDA Pro via File -> Script File... (Alt + F7). Colors critical functions (Red for injection, Orange for crypto, Blue for C2, Green for safe).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "target_file": {
                    "type": "string",
                    "description": "Name of the target analyzed binary"
                },
                "functions": {
                    "type": "array",
                    "description": "List of functions to annotate, rename, type and color-code",
                    "items": {
                        "type": "object",
                        "properties": {
                            "ea": {"type": "string", "description": "Virtual address (e.g. '0x004014D2')"},
                            "name": {"type": "string", "description": "New clean function name"},
                            "type": {"type": "string", "description": "C function prototype declaration (optional)"},
                            "comment": {"type": "string", "description": "Function documentation comment"},
                            "category": {
                                "type": "string",
                                "enum": ["critical_injection", "crypto_obfuscation", "network_c2", "safe_routine", "suspicious", "none"],
                                "description": "Category for automatic color coding in IDA Pro"
                            }
                        },
                        "required": ["ea", "name"]
                    }
                },
                "comments": {
                    "type": "array",
                    "description": "List of specific instruction comments",
                    "items": {
                        "type": "object",
                        "properties": {
                            "ea": {"type": "string"},
                            "text": {"type": "string"},
                            "repeatable": {"type": "boolean"}
                        },
                        "required": ["ea", "text"]
                    }
                },
                "output_path": {
                    "type": "string",
                    "description": "Destination path for the .py script (default: C:\\REA-Context\\ida_patch.py)"
                }
            },
            "required": ["target_file", "functions"]
        }
    }
]

CATALOG_ITEMS = [
    {"name": "re-triage", "category": "pe, triage", "cmd": "bt re-triage <file>", "desc": "Fast binary header inspection, sections, entropy, and architecture."},
    {"name": "re-strings", "category": "strings, ioc", "cmd": "bt re-strings <file>", "desc": "Extracts and filters suspicious URLs, IPs, API imports, and ASCII/Unicode strings."},
    {"name": "read-range", "category": "inspection, slice", "cmd": "bt read-range -Path <f> -Start <N> -End <M>", "desc": "Reads surgical line ranges from disassembly listings."},
    {"name": "re-diff-dirs", "category": "diff, unpack", "cmd": "bt re-diff-dirs -Dir1 <d1> -Dir2 <d2>", "desc": "Diffs directory contents before and after malware execution/unpacking."},
    {"name": "re-ida-export", "category": "ida, export", "cmd": "bt re-ida-export -InputJson <j> -Output <out.py>", "desc": "Exports annotations and color-coded routines into IDAPython script for Alt+F7."}
]

def handle_call_tool(name: str, args: dict) -> str:
    global evidence_store

    if name == "rea_catalog":
        filt = args.get("filter", "").lower()
        matched = [c for c in CATALOG_ITEMS if not filt or filt in c["name"] or filt in c["category"] or filt in c["desc"].lower()]
        return json.dumps({"capabilities": matched, "total": len(matched)}, indent=2)

    elif name == "rea_run":
        tool_name = args["tool_name"]
        cmd = args["command"]
        summary = args.get("summary")
        run_cwd = args.get("cwd")
        if run_cwd and not os.path.isdir(run_cwd):
            run_cwd = None

        # Execute command safely via powershell
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd],
            capture_output=True,
            text=True,
            timeout=180,
            cwd=run_cwd
        )
        output = proc.stdout + ("\nSTDERR:\n" + proc.stderr if proc.stderr else "")
        if not output.strip():
            output = f"[Empty output, ExitCode: {proc.returncode}]"

        # Intercept and store to NVMe
        res = evidence_store.store_evidence(tool_name=tool_name, content=output, summary=summary)
        return json.dumps(res, indent=2)

    elif name == "rea_search_evidence":
        query = args["query"]
        limit = args.get("limit", 5)
        hits = evidence_store.search(query=query, limit=limit)
        return json.dumps({"query": query, "hits_count": len(hits), "results": hits}, indent=2)

    elif name == "rea_read_chunk":
        ev_id = args["evidence_id"]
        offset = args.get("offset", 0)
        count = min(100, max(1, args.get("count", 40)))
        chunk = evidence_store.read_chunk(evidence_id=ev_id, offset=offset, count=count)
        return json.dumps(chunk, indent=2)

    elif name == "rea_export_ida":
        out_path = args.get("output_path", r"C:\REA-Context\ida_patch.py")
        script = generate_idapython_script(args)
        p = Path(out_path)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(script, encoding="utf-8")
        return json.dumps({
            "status": "success",
            "output_path": str(p),
            "script_bytes": len(script),
            "message": f"IDAPython script successfully written to {p}. Open IDA Pro and run Alt + F7 to apply!"
        }, indent=2)

    else:
        return json.dumps({"error": f"Unknown tool '{name}'"})


def main():
    """Stdio JSON-RPC loop adhering strictly to MCP 2024-11-05 protocol."""
    # Ensure stdout is in unbuffered/line mode
    sys.stdin.reconfigure(encoding="utf-8")
    sys.stdout.reconfigure(encoding="utf-8")

    while True:
        line = sys.stdin.readline()
        if not line:
            break
        line = line.strip()
        if not line:
            continue

        try:
            req = json.loads(line)
        except Exception:
            continue

        req_id = req.get("id")
        method = req.get("method")
        params = req.get("params", {})

        try:
            log_dir = Path(r"C:\REA-Context\logs")
            log_dir.mkdir(parents=True, exist_ok=True)
            with open(log_dir / "gateway.log", "a", encoding="utf-8") as f:
                f.write(f"[{method}] id={req_id} params={list(params.keys())}\n")
        except Exception:
            pass

        if method == "initialize":
            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "rea-meta-gateway", "version": "1.0.0"}
                }
            }
            sys.stdout.write(json.dumps(res) + "\n")
            sys.stdout.flush()

        elif method == "notifications/initialized":
            # No response needed for notification
            pass

        elif method == "tools/list":
            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"tools": TOOLS_DEFINITIONS}
            }
            sys.stdout.write(json.dumps(res) + "\n")
            sys.stdout.flush()

        elif method == "tools/call":
            tool_name = params.get("name")
            tool_args = params.get("arguments", {})
            try:
                text_result = handle_call_tool(tool_name, tool_args)
            except Exception as e:
                text_result = json.dumps({"error": str(e)})

            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": text_result}]
                }
            }
            sys.stdout.write(json.dumps(res) + "\n")
            sys.stdout.flush()

        elif req_id is not None:
            # Unsupported method response
            res = {
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Method '{method}' not found"}
            }
            sys.stdout.write(json.dumps(res) + "\n")
            sys.stdout.flush()

if __name__ == "__main__":
    main()
