# Azure AI Search hybrid+semantic


from __future__ import annotations
import requests
from typing import Dict, Any, List, Tuple
from .config import get_settings

class AzureAISearch:
    def __init__(self):
        s = get_settings().search
        self.endpoint = s.endpoint.rstrip("/")
        self.api_key = s.api_key
        self.index = s.index
        self.api_version = s.api_version
        self.session = requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "api-key": self.api_key
        })

    def hybrid_semantic(self, query: str, top: int = 5, select: str | None = None) -> Dict[str, Any]:
        """
        Runs Modern RAG hybrid query:
          - lexical `search`
          - vectorQueries=[{kind:'text'}] against 'chunkVector'
          - queryType='semantic' with answers/captions
        """
        body = {
            "search": query,
            "queryType": "semantic",
            "semanticConfiguration": "mem-semantic",
            "answers": "extractive|count-3",
            "captions": "extractive|highlight-true",
            "vectorQueries": [
                {"kind": "text", "text": query, "fields": "chunkVector", "k": 50, "weight": 1.0}
            ],
            "top": top
        }
        if select:
            body["select"] = select

        url = f"{self.endpoint}/indexes/{self.index}/docs/search?api-version={self.api_version}"
        resp = self.session.post(url, json=body, timeout=30)
        resp.raise_for_status()
        return resp.json()

def extract_citations(search_json: Dict[str, Any], max_snippets: int = 3) -> List[Tuple[str, str]]:
    """
    Returns [(doc_id, snippet)] from top results.
    The index is chunk-level; use 'id' or available fields.
    """
    hits = search_json.get("value", [])[:max_snippets]
    out: List[Tuple[str, str]] = []
    for h in hits:
        doc_id = h.get("id") or h.get("@search.documentId") or "doc"
        snippet = h.get("@search.captions", [{}])[0].get("text") or h.get("chunk") or ""
        out.append((str(doc_id), snippet))
    return out
