from __future__ import annotations
import json, os, time
import requests
from typing import Dict, Any
from rag_agent.config import get_settings
from datetime import date

class SearchClient:
    def __init__(self):
        s = get_settings().search
        self.endpoint = s.endpoint.rstrip("/")
        self.index = s.index
        self.api_version = s.api_version
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json", "api-key": s.api_key})

    def post(self, body: Dict[str, Any]) -> Dict[str, Any]:
        url = f"{self.endpoint}/indexes/{self.index}/docs/search?api-version={self.api_version}"
        r = self.session.post(url, json=body, timeout=30)
        r.raise_for_status()
        return r.json()

def run_metadata(mode: str, k_candidates: int, top_k: int) -> Dict[str, Any]:
    s = get_settings()
    return {
        "mode": mode,
        "k_candidates": k_candidates,
        "top_k": top_k,
        "search_index": s.search.index,
        "search_api_version": s.search.api_version,
        "endpoint": s.search.endpoint,
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "notes": "Modern RAG baseline evaluation with fixed k_candidates=50, top=10"
    }

def get_eval_today() -> date:
    # EVAL_TODAY=YYYY-MM-DD (optional)
    s = os.getenv("EVAL_TODAY")
    if not s:
        return date.today()
    y, m, d = [int(x) for x in s.split("-")]
    return date(y, m, d)