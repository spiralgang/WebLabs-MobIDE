from __future__ import annotations
import sqlite3, fnmatch, os
from dataclasses import dataclass
from typing import Iterable, List, Optional, Tuple

@dataclass
class FTSResult:
    path: str
    snippet: str
    score: float

@dataclass
class FTSQuery:
    text: str
    limit: int = 10

class SqliteFTS:
    """
    FTS over techula_index.db with automatic fallback to tokens table.
    Respects allow_roots and include/exclude filters during result filtering.
    """
    def __init__(self, db_path: str, allow_roots: Iterable[str], include_ext: Iterable[str], exclude_glob: Iterable[str]) -> None:
        self.db_path = db_path
        self.allow_roots = tuple(os.path.abspath(p) for p in allow_roots)
        self.include_ext = {e.lower() for e in include_ext} if include_ext else set()
        self.exclude_glob = list(exclude_glob) if exclude_glob else []

        self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        # user_version=1 indicates FTS5 mode per content_indexer.py
        self._is_fts = self._conn.execute("PRAGMA user_version").fetchone()[0] == 1

    def _allowed(self, path: str) -> bool:
        ap = os.path.abspath(path)
        if self.allow_roots and not any(ap.startswith(root.rstrip(os.sep)+os.sep) or ap == root for root in self.allow_roots):
            return False
        if self.include_ext:
            if not any(ap.lower().endswith(ext) for ext in self.include_ext):
                return False
        for pat in self.exclude_glob:
            if fnmatch.fnmatch(ap, pat):
                return False
        return True

    def search(self, q: FTSQuery) -> List[FTSResult]:
        if self._is_fts:
            # simple BM25-ish via FTS; use snippet if available
            rows = self._conn.execute(
                "SELECT path, snippet(content_fts, 1, '[', ']', '…', 10) AS snip FROM content_fts WHERE content_fts MATCH ? LIMIT ?",
                (q.text, q.limit)
            ).fetchall()
            results = [FTSResult(r["path"], r["snip"] or "", 1.0) for r in rows if self._allowed(r["path"])]
        else:
            # tokens fallback: naive AND semantics
            terms = [t for t in q.text.split() if t]
            if not terms:
                return []
            sets = []
            for t in terms:
                rs = self._conn.execute("SELECT path FROM content_tokens WHERE term=?", (t.lower(),)).fetchall()
                sets.append({r["path"] for r in rs})
            paths = set.intersection(*sets) if sets else set()
            results = []
            for p in list(paths)[: q.limit * 3]:
                if not self._allowed(p):
                    continue
                # fetch small body if available
                body = self._conn.execute("SELECT body FROM content_fts WHERE path=?", (p,)).fetchone() if self._is_fts else None
                snip = (body["body"][:200] + "…") if body and body["body"] else ""
                results.append(FTSResult(p, snip, 1.0))
            results = results[: q.limit]
        return results

    def close(self) -> None:
        try:
            self._conn.close()
        except Exception:
            pass

# References:
# - /reference vault (SQLite FTS5 usage & fallbacks)