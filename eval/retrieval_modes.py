from __future__ import annotations
from typing import List, Dict, Any
from .eval_common import SearchClient
from .normalize import normalize_for_retrieval

SELECT_FIELDS = "id,chunk,content,membership_status_original,membership_type_original,gradeName,hubName"

def _post(body) -> List[str]:
    return [v["id"] for v in SearchClient().post(body).get("value", [])]

def vector_only(query: str, k_candidates: int = 50, top_k: int = 10) -> List[str]:
    lex, vec, filt = normalize_for_retrieval(query)
    body = {
        "vectorQueries": [{"kind": "text", "text": vec, "fields": "chunkVector", "k": k_candidates, "weight": 1.0}],
        "top": top_k, "select": SELECT_FIELDS
    }
    if filt: body["filter"] = filt
    return _post(body)

def hybrid_rrf(query: str, k_candidates: int = 50, top_k: int = 10) -> List[str]:
    lex, vec, filt = normalize_for_retrieval(query)
    body = {
        "search": lex,
        "vectorQueries": [{"kind": "text", "text": vec, "fields": "chunkVector", "k": k_candidates, "weight": 1.0}],
        "top": top_k, "select": SELECT_FIELDS
    }
    if filt: body["filter"] = filt
    return _post(body)

def hybrid_semantic(query: str, k_candidates: int = 50, top_k: int = 10) -> List[str]:
    lex, vec, filt = normalize_for_retrieval(query)
    body = {
        "search": lex,
        "queryType": "semantic",
        "semanticConfiguration": "mem-semantic",
        "vectorQueries": [{"kind": "text", "text": vec, "fields": "chunkVector", "k": k_candidates, "weight": 1.0}],
        "top": top_k, "select": SELECT_FIELDS
    }
    if filt: body["filter"] = filt
    return _post(body)