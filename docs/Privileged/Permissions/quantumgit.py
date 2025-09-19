from __future__ import annotations
import hashlib, json, random, time
from dataclasses import dataclass, field
from typing import Dict, Set, Optional, Tuple, List

@dataclass
class QuantumCommit:
    h: str
    parallel_states: Set[str]
    weights: Dict[str, float]
    entangled: Set[str]
    meta: Dict[str, str] = field(default_factory=dict)

class QuantumRepository:
    """
    Quantum-inspired metadata for NNMM “mind states”:
    - Commit exists in multiple branches (parallel_states) with probabilities (weights).
    - Observation collapses to a concrete head per branch (branch_heads).
    """
    def __init__(self, seed: Optional[int] = None) -> None:
        self.superpos: Dict[str, QuantumCommit] = {}
        self.branch_heads: Dict[str, str] = {}
        self.entangle_map: Dict[str, Set[str]] = {}
        self._rnd = random.Random(seed or int(time.time()*1000))

    def _hash(self, changes: Dict[str, any], probs: Dict[str, float]) -> str:
        blob = json.dumps({"changes": changes, "probs": probs}, sort_keys=True).encode()
        return hashlib.sha256(blob).hexdigest()[:16]

    def commit_superposition(self, changes: Dict[str, any], branch_probabilities: Dict[str, float], meta: Optional[Dict[str,str]]=None) -> str:
        commit_hash = self._hash(changes, branch_probabilities)
        qc = QuantumCommit(
            h=commit_hash,
            parallel_states=set(branch_probabilities.keys()),
            weights=branch_probabilities,
            entangled=self._find_entangled(changes),
            meta=meta or {}
        )
        self.superpos[commit_hash] = qc
        for eid in qc.entangled:
            self.entangle_map.setdefault(eid, set()).add(commit_hash)
        return commit_hash

    def observe_branch(self, branch: str) -> Optional[str]:
        affected = [c for c in self.superpos.values() if branch in c.parallel_states]
        head: Optional[str] = None
        for c in affected:
            p = c.weights.get(branch, 0.0)
            if self._rnd.random() < p:
                head = c.h
                self.branch_heads[branch] = c.h
        return head

    def collapse_to(self, commit_hash: str, branch: str) -> None:
        if commit_hash not in self.superpos:
            return
        self.branch_heads[branch] = commit_hash

    def _find_entangled(self, changes: Dict[str, any]) -> Set[str]:
        # Simple signal-based entanglement marker
        keys = sorted(changes.keys())
        sig = hashlib.md5("::".join(keys).encode()).hexdigest()[:8]
        return {sig}

# References:
# - /reference vault (quantum versioning metaphors)