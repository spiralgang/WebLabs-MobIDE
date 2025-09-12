from __future__ import annotations
from .base import BaseBot
from ..types import BotType, HeatLevel, BotMessage
from ..adapters.qdataset_adapter import QDataSetAdapter

class WebIntelBot(BaseBot):
    def __init__(self, qd: QDataSetAdapter) -> None:
        super().__init__(BotType.WEBINTEL)
        self.qd = qd

    def activate(self, context: str, heat: HeatLevel) -> str:
        if not self.qd.available:
            return "QDataSet not available. Skipping."
        names = self.qd.list_datasets()
        preview = names[:5]
        self.emit(BotMessage(self.bot_type, "intel.datasets", {"datasets": preview}, heat))
        return f"Quantum datasets available (sample): {', '.join(preview) if preview else 'none'}"

    def receive(self, msg: BotMessage) -> None:
        # Could pull targeted samples based on ThinkBot topics
        pass

# References:
# - /reference vault
# - eperrier/QDataSet