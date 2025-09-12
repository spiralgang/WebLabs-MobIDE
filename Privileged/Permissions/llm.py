from __future__ import annotations
from typing import Optional, Sequence, Dict, Any, List
from dataclasses import dataclass

@dataclass
class LLMConfig:
    provider: str  # "none"|"llama_cpp"|"transformers"
    model: str
    max_new_tokens: int = 256

class LocalLLM:
    """
    Pluggable local LLM facade. If unavailable, falls back to extractive answer stitching.
    Android/UserLAnd note: CPU-only models can be slow; keep models tiny (<=1B params quantized) or skip.
    """
    def __init__(self, cfg: LLMConfig) -> None:
        self.cfg = cfg
        self._ready = False
        self._impl = None
        self._init()

    def _init(self) -> None:
        if self.cfg.provider == "llama_cpp":
            try:
                from llama_cpp import Llama  # type: ignore
                self._impl = Llama(model_path=self.cfg.model, n_ctx=4096, n_threads=2)
                self._ready = True
            except Exception:
                self._ready = False
        elif self.cfg.provider == "transformers":
            try:
                from transformers import AutoModelForCausalLM, AutoTokenizer  # type: ignore
                tok = AutoTokenizer.from_pretrained(self.cfg.model)
                mdl = AutoModelForCausalLM.from_pretrained(self.cfg.model, trust_remote_code=True)
                self._impl = (tok, mdl)
                self._ready = True
            except Exception:
                self._ready = False
        else:
            self._ready = False

    def generate(self, prompt: str) -> str:
        if not self._ready or self._impl is None:
            # Fallback: return prompt tail (caller composes with snippets)
            return ""
        if self.cfg.provider == "llama_cpp":
            out = self._impl(prompt=prompt, max_tokens=self.cfg.max_new_tokens, temperature=0.2)
            return out["choices"][0]["text"]
        elif self.cfg.provider == "transformers":
            tok, mdl = self._impl
            ids = tok(prompt, return_tensors="pt")
            out_ids = mdl.generate(**ids, max_new_tokens=self.cfg.max_new_tokens)
            return tok.decode(out_ids[0], skip_special_tokens=True)
        return ""

# References:
# - /reference vault (local LLM selection; CPU-only constraints under Android/User)