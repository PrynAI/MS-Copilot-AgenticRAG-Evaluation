from __future__ import annotations
from typing import List, Set, Dict

def recall_at_k(pred: List[str], gold: Set[str], k: int = 10) -> float:
    if not gold:
        return 0.0
    return len(set(pred[:k]).intersection(gold)) / float(len(gold))

def mrr_at_k(pred: List[str], gold: Set[str], k: int = 10) -> float:
    for i, doc_id in enumerate(pred[:k], start=1):
        if doc_id in gold:
            return 1.0 / i
    return 0.0