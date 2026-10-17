"""
Phase 1 Unit Test: REA Persistent Evidence Store & SQLite FTS5 Benchmark
"""

import sys
import time
import shutil
from pathlib import Path

# Add tools to path
tools_dir = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(tools_dir))

from rea_evidence_db import REAEvidenceStore

def run_phase1_test():
    test_base = Path(r"C:\REA-Context")
    test_session_id = "test_verification_phase1"
    test_session_dir = test_base / "sessions" / test_session_id

    # Clean up previous run if exists
    if test_session_dir.exists():
        shutil.rmtree(test_session_dir)

    print(f"[*] Step 1: Initializing REA Evidence Store at {test_base} (Session: {test_session_id})...")
    store = REAEvidenceStore(base_dir=str(test_base), session_id=test_session_id)
    assert test_session_dir.exists(), "Session directory was not created!"
    assert (test_session_dir / "index.sqlite").exists(), "index.sqlite was not created!"
    print("    [+] Directories and SQLite database initialized successfully.")

    print("[*] Step 2: Generating realistic 20,000-line reverse engineering disassembly dump...")
    lines = []
    for i in range(1, 20001):
        if i == 450:
            lines.append("00401000: 48 83 EC 28          sub rsp, 28h ; Entry point of stealth loader")
        elif i == 1234:
            lines.append("004014D2: FF 15 A0 20 40 00    call cs:VirtualAllocEx ; Allocates RWX injection buffer")
        elif i == 5678:
            lines.append("00402AB4: E8 47 01 00 00       call rc4_decrypt_payload ; Decrypts secondary stage payload")
        elif i == 14200:
            lines.append("004071A0: 48 8D 0D 20 10 00 00 lea rcx, aC2Beacon ; String: 'https://c2-malicious.domain/beacon'")
        else:
            lines.append(f"00{i:06X}: 90                   nop ; routine padding block {i}")

    sample_dump = "\n".join(lines)
    dump_size_kb = len(sample_dump.encode("utf-8")) / 1024
    print(f"    [+] Generated mock dump: 20,000 lines, {dump_size_kb:.2f} KB.")

    print("[*] Step 3: Storing raw dump into NVMe Evidence Store...")
    t0 = time.perf_counter()
    res = store.store_evidence(
        tool_name="ghidra_decompile_routine",
        content=sample_dump,
        summary="Ghidra decompilation listing of main binary segment with injection routines"
    )
    t_store = (time.perf_counter() - t0) * 1000
    print(f"    [+] Stored evidence: ID={res['evidence_id']}, Lines={res['lines']}, Bytes={res['bytes']} in {t_store:.2f} ms")
    assert res["evidence_id"] == "EV-0001", "Expected ID EV-0001"
    assert (test_session_dir / "raw" / "result-000001.json").exists(), "Raw JSON file missing on NVMe!"

    print("[*] Step 4: Benchmarking sub-millisecond SQLite FTS5 search...")
    test_queries = ["VirtualAllocEx", "rc4_decrypt_payload", "c2-malicious.domain"]
    for q in test_queries:
        t_search_start = time.perf_counter()
        hits = store.search(q, limit=5)
        t_search_ms = (time.perf_counter() - t_search_start) * 1000
        print(f"    [+] Query '{q}' -> {len(hits)} hit(s) in {t_search_ms:.3f} ms")
        assert len(hits) > 0, f"Query '{q}' returned no results!"
        snippet = hits[0]["snippet"]
        print(f"        Snippet: {snippet.strip()[:100]}...")
        assert t_search_ms < 50.0, f"Search took too long ({t_search_ms:.2f} ms > 50 ms)"

    print("[*] Step 5: Testing surgical chunk reading (read_chunk)...")
    chunk = store.read_chunk(evidence_id="EV-0001", offset=1230, count=8)
    assert "error" not in chunk, chunk.get("error")
    assert chunk["count"] == 8, f"Expected 8 lines, got {chunk['count']}"
    assert "VirtualAllocEx" in chunk["lines"], "Expected VirtualAllocEx in chunk lines"
    print("    [+] Surgical read (8 lines around line 1234):")
    for l in chunk["lines"].splitlines():
        print(f"        {l}")

    print("[*] Step 6: Testing persistent state reattachment across restarts...")
    store_reloaded = REAEvidenceStore(base_dir=str(test_base), session_id=test_session_id)
    stats = store_reloaded.get_session_stats()
    assert stats["evidence_count"] == 1, f"Expected 1 evidence, found {stats['evidence_count']}"
    assert stats["db_size_bytes"] > 0, "Database size is 0"
    print(f"    [+] Reloaded session state successfully: Evidences={stats['evidence_count']}, Total Bytes={stats['total_bytes']}, DB Size={stats['db_size_bytes']} bytes.")

    print("\n" + "="*50)
    print(">>> PHASE 1 TEST: PASSED (100% SUCCESS) <<<")
    print("="*50)

if __name__ == "__main__":
    run_phase1_test()
