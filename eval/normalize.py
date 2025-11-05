from __future__ import annotations
from typing import Tuple, Optional
from datetime import date
from rag_agent.sql_templates import parse_time_window
from rag_agent.intent_router import detect_metric
from .eval_common import get_eval_today

def month_anchor_label(granularity: str, start_fk: int) -> str:
    y = start_fk // 10000
    m = (start_fk // 100) % 100
    return f"{y:04d}-{m:02d}" if granularity == "month" else f"{y:04d}"

def build_filter(metric: str) -> str:
    if metric == "active":
        return "membership_status_original eq 'Active'"
    if metric == "admissions":
        return "membership_type_original eq 'Join'"
    if metric == "upgrades":
        return "membership_type_original eq 'Upgrade'"
    if metric == "left":
        return "(membership_status_original eq 'Resigned' or membership_status_original eq 'Deceased')"
    return ""

def normalize_for_retrieval(qtext: str) -> Tuple[str, str, Optional[str]]:
    """
    Returns: (lexical_query, vector_text, optional_filter)
    Injects month anchor token and categorical filter to align with index content.
    """
    metric = detect_metric(qtext)
    granularity, tw = parse_time_window(qtext, today=get_eval_today())
    anchor = month_anchor_label(granularity, tw.start_fk)  # e.g., "2025-10"
    base = qtext.strip()

    # Append an explicit temporal hint so lexical + semantic models can match "Active: YYYY-MM-DD".
    lex = f"{base} {anchor}"
    vec = f"{metric} memberships in {anchor}"
    filt = build_filter(metric)
    return lex, vec, filt or None