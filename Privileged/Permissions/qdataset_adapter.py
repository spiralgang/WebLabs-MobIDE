from __future__ import annotations
from typing import List, Tuple

class QDataSetAdapter:
    """
    Optional adapter to eperrier/QDataSet (if installed).
    Provides list of available datasets and sample access.
    """
    def __init__(self) -> None:
        self.available = False
        try:
            import qdataset  # hypothetical module; adjust to actual package if different
            self.qd = qdataset
            self.available = True
        except Exception:
            self.qd = None

    def list_datasets(self) -> List[str]:
        if not self.available:
            return []
        try:
            return getattr(self.qd, "list_datasets", lambda: [])()
        except Exception:
            return []

    def get_samples(self, name: str, n: int = 5) -> List[Tuple[str, str]]:
        """
        Return a few (text,label) or (text,meta) pairs if supported.
        """
        if not self.available:
            return []
        try:
            loader = getattr(self.qd, "load", None)
            if not loader:
                return []
            ds = loader(name)
            out = []
            for i, item in enumerate(ds):
                if i >= n:
                    break
                out.append((str(item), getattr(item, "label", "")))
            return out
        except Exception:
            return []

# References:
# - /reference vault (adapter safety and optionality)
# - eperrier/QDataSet repository (API may differ; this is defensive)