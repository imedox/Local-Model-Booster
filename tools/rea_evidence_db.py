"""
REA Persistent Evidence Store
High-performance NVMe storage + SQLite FTS5 full-text search engine for reverse engineering artifacts.
Part of Local-Model-Booster.
"""

import os
import json
import sqlite3
import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List

DEFAULT_BASE_DIR = os.environ.get("REA_CONTEXT_DIR", r"C:\REA-Context")


class REAEvidenceStore:
    def __init__(self, base_dir: str = DEFAULT_BASE_DIR, session_id: Optional[str] = None):
        self.base_dir = Path(base_dir)
        self.sessions_dir = self.base_dir / "sessions"
        self.logs_dir = self.base_dir / "logs"

        # Create base folders
        self.sessions_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(parents=True, exist_ok=True)

        if not session_id:
            # Use latest or default
            today = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            session_id = f"session_{today}"

        self.session_id = session_id
        self.session_dir = self.sessions_dir / self.session_id
        self.raw_dir = self.session_dir / "raw"
        self.raw_dir.mkdir(parents=True, exist_ok=True)

        self.db_path = self.session_dir / "index.sqlite"
        self.state_path = self.session_dir / "state.json"

        self._init_db()
        self._init_state()

    def _get_connection(self) -> sqlite3.Connection:
        con = sqlite3.connect(str(self.db_path), timeout=10.0)
        con.execute("PRAGMA journal_mode=WAL;")
        con.execute("PRAGMA synchronous=NORMAL;")
        return con

    def _init_db(self):
        with self._get_connection() as con:
            cur = con.cursor()
            # Meta table for fast structured lookups
            cur.execute("""
                CREATE TABLE IF NOT EXISTS evidence_meta (
                    id TEXT PRIMARY KEY,
                    tool_name TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    byte_size INTEGER NOT NULL,
                    line_count INTEGER NOT NULL,
                    summary TEXT,
                    raw_filename TEXT NOT NULL
                );
            """)

            # FTS5 virtual table for lightning-fast full text search
            cur.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS evidence_fts USING fts5(
                    id,
                    tool_name,
                    content,
                    tokenize='porter unicode61'
                );
            """)
            con.commit()

    def _init_state(self):
        if not self.state_path.exists():
            state = {
                "session_id": self.session_id,
                "created_at": datetime.datetime.now().isoformat(),
                "evidence_count": 0,
                "total_bytes": 0
            }
            self.state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")

    def store_evidence(self, tool_name: str, content: str, summary: Optional[str] = None) -> Dict[str, Any]:
        """
        Stores raw tool output to NVMe disk, indexes full text into SQLite FTS5,
        and returns a compact metadata dictionary (< 100 tokens).
        """
        # Load and update state
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        count = state.get("evidence_count", 0) + 1
        evidence_id = f"EV-{count:04d}"
        raw_filename = f"result-{count:06d}.json"
        raw_file_path = self.raw_dir / raw_filename

        timestamp = datetime.datetime.now().isoformat()
        byte_size = len(content.encode("utf-8"))
        lines = content.splitlines()
        line_count = len(lines)

        # Generate automatic summary if not provided
        if not summary:
            preview = lines[:5]
            summary = f"[{tool_name}] {line_count} lines, {byte_size} bytes. Preview: " + " | ".join(l.strip() for l in preview if l.strip())[:180]

        # Write raw content to NVMe
        payload = {
            "id": evidence_id,
            "tool_name": tool_name,
            "timestamp": timestamp,
            "byte_size": byte_size,
            "line_count": line_count,
            "summary": summary,
            "content": content
        }
        raw_file_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

        # Index in SQLite
        with self._get_connection() as con:
            cur = con.cursor()
            cur.execute(
                "INSERT INTO evidence_meta (id, tool_name, timestamp, byte_size, line_count, summary, raw_filename) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (evidence_id, tool_name, timestamp, byte_size, line_count, summary, raw_filename)
            )
            cur.execute(
                "INSERT INTO evidence_fts (id, tool_name, content) VALUES (?, ?, ?)",
                (evidence_id, tool_name, content)
            )
            con.commit()

        # Update state
        state["evidence_count"] = count
        state["total_bytes"] = state.get("total_bytes", 0) + byte_size
        state["last_updated"] = timestamp
        self.state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")

        return {
            "evidence_id": evidence_id,
            "tool_name": tool_name,
            "lines": line_count,
            "bytes": byte_size,
            "summary": summary,
            "hint": f"To read lines call rea_read_chunk(id='{evidence_id}', offset=0, count=50) or rea_search_evidence(query='...')"
        }

    @staticmethod
    def _sanitize_fts_query(query: str) -> str:
        """
        Safely formats arbitrary user queries (including URLs, symbols, hex addresses,
        and punctuation like '.', ':', '-') into valid SQLite FTS5 phrase tokens.
        """
        import re
        cleaned = query.replace('"', ' ').strip()
        if not cleaned:
            return '""'
        # Extract whitespace-separated tokens
        tokens = [t.strip() for t in re.findall(r'[^\s]+', cleaned) if t.strip()]
        if not tokens:
            return '""'
        # Wrap every token in double quotes to prevent FTS5 operator collisions (e.g. '.', '-', ':')
        return " AND ".join(f'"{t}"' for t in tokens)

    def search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Performs sub-millisecond FTS5 search across all indexed evidence.
        """
        safe_query = self._sanitize_fts_query(query)
        with self._get_connection() as con:
            cur = con.cursor()
            try:
                cur.execute("""
                    SELECT 
                        evidence_fts.id,
                        evidence_fts.tool_name,
                        snippet(evidence_fts, 2, '>>> ', ' <<<', '...', 20) AS snippet,
                        evidence_meta.line_count,
                        evidence_meta.byte_size,
                        evidence_meta.summary
                    FROM evidence_fts
                    JOIN evidence_meta ON evidence_fts.id = evidence_meta.id
                    WHERE evidence_fts MATCH ?
                    ORDER BY rank
                    LIMIT ?;
                """, (safe_query, limit))
            except sqlite3.OperationalError:
                # Ultimate fallback: strip all non-alphanumeric characters
                import re
                fallback_tokens = re.findall(r'\w+', query)
                if not fallback_tokens:
                    return []
                fallback_query = " AND ".join(f'"{t}"' for t in fallback_tokens)
                cur.execute("""
                    SELECT 
                        evidence_fts.id,
                        evidence_fts.tool_name,
                        snippet(evidence_fts, 2, '>>> ', ' <<<', '...', 20) AS snippet,
                        evidence_meta.line_count,
                        evidence_meta.byte_size,
                        evidence_meta.summary
                    FROM evidence_fts
                    JOIN evidence_meta ON evidence_fts.id = evidence_meta.id
                    WHERE evidence_fts MATCH ?
                    LIMIT ?;
                """, (fallback_query, limit))

            rows = cur.fetchall()

        results = []
        for row in rows:
            results.append({
                "id": row[0],
                "tool_name": row[1],
                "snippet": row[2],
                "total_lines": row[3],
                "bytes": row[4],
                "summary": row[5]
            })
        return results

    def read_chunk(self, evidence_id: str, offset: int = 0, count: int = 50) -> Dict[str, Any]:
        """
        Surgically reads a slice of lines from an evidence item without bloating context.
        """
        with self._get_connection() as con:
            cur = con.cursor()
            cur.execute("SELECT raw_filename, line_count, tool_name FROM evidence_meta WHERE id = ?", (evidence_id,))
            row = cur.fetchone()

        if not row:
            return {"error": f"Evidence {evidence_id} not found"}

        raw_filename, total_lines, tool_name = row
        raw_file_path = self.raw_dir / raw_filename

        if not raw_file_path.exists():
            return {"error": f"Raw file {raw_filename} missing from disk"}

        raw_data = json.loads(raw_file_path.read_text(encoding="utf-8"))
        lines = raw_data.get("content", "").splitlines()

        # Clamp range
        start = max(0, offset)
        end = min(len(lines), start + max(1, count))
        selected_lines = lines[start:end]

        formatted = "\n".join(f"{start + i + 1:6d}: {line}" for i, line in enumerate(selected_lines))

        return {
            "id": evidence_id,
            "tool_name": tool_name,
            "total_lines": total_lines,
            "offset": start,
            "count": len(selected_lines),
            "remaining": max(0, total_lines - end),
            "lines": formatted
        }

    def get_session_stats(self) -> Dict[str, Any]:
        """Returns session health, item count, and database size."""
        state = json.loads(self.state_path.read_text(encoding="utf-8"))
        db_size = self.db_path.stat().st_size if self.db_path.exists() else 0
        state["db_size_bytes"] = db_size
        return state
