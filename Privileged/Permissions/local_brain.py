from __future__ import annotations
from dataclasses import dataclass
from typing import Iterable, List, Optional
import os, textwrap

from index.sqlite_fts import SqliteFTS, FTSResult
from index.router import IndexRouter, RetrievalRequest, RetrievalResult
from .llm import LocalLLM, LLMConfig

@dataclass
class BotView:
    name: str
    allow_roots: List[str]
    include_ext: List[str]
    exclude_glob: List[str]
    indices: List[dict]
    llm: LLMConfig

class LocalBrain:
    """
    Orchestrates retrieval + (optional) generation.
    - Dedup-aware via upstream index pre-processing (SimHash/CDC influence your corpus).
    - Non-contaminating: each bot has its own allowlist roots and filters.
    """
    def __init__(self, state_dir: str, view: BotView) -> None:
        db_path = os.path.join(state_dir, "techula_index.db")
        self.fts = SqliteFTS(db_path, view.allow_roots, view.include_ext, view.exclude_glob)
        self.router = IndexRouter(self.fts)
        self.llm = LocalLLM(view.llm)

    def answer(self, q: str, top_k: int = 6) -> str:
        rr: RetrievalResult = self.router.retrieve(RetrievalRequest(query=q, top_k=top_k))
        snippets = self._format_snippets(rr.hits)
        if not snippets:
            return "No relevant documents found in your local index."
        if self.llm.cfg.provider == "none":
            # Extractive concise answer: show ranked snippets
            return snippets
        prompt = self._compose_prompt(q, rr.hits)
        gen = self.llm.generate(prompt)
        if not gen.strip():
            return snippets
        return gen

    def _format_snippets(self, hits: List[FTSResult]) -> str:
        lines: List[str] = []
        for i, h in enumerate(hits, 1):
            lines.append(f"{i}. {h.path}\n   {textwrap.shorten(h.snippet.replace('\\n',' '), width=240, placeholder='…')}")
        return "\n".join(lines)

    def _compose_prompt(self, q: str, hits: List[FTSResult]) -> str:
        ctx_parts: List[str] = []
        for h in hits[:6]:
            ctx_parts.append(f"[{h.path}]\n{h.snippet}\n")
        ctx = "\n".join(ctx_parts)
        return f"""You are a local assistant. Answer strictly from the context.
Question: {q}
Context:
{ctx}
Answer:"""

    def close(self) -> None:
        try:
            self.fts.close()
        except Exception:
            pass

# References:
# - /reference vault (RAG compositional patterns, snippet-first fallback)