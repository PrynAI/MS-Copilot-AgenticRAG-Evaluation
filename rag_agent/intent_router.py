# metric/list vs explain + breakdowns


from __future__ import annotations
import re
from typing import Literal, Optional, Tuple

Metric = Literal["active","admissions","upgrades","left"]
Breakdown = Optional[Literal["month","grade","region","gender"]]

def detect_metric(text: str) -> Metric:
    t = text.lower()
    if re.search(r"\bupgrade(s)?\b", t):
        return "upgrades"
    if re.search(r"\b(admission|join|joins)\b", t):
        return "admissions"
    if re.search(r"\b(left|leavers|attrition|resign(ed|ations)?)\b", t):
        return "left"
    return "active"

def detect_breakdown(text: str) -> Breakdown:
    t = text.lower()
    if "by month" in t:
        return "month"
    if "by grade" in t:
        return "grade"
    if "by region" in t:
        return "region"
    if "by gender" in t:
        return "gender"
    return None

def is_metric_or_list_query(text: str) -> bool:
    t = text.lower()
    return bool(re.search(r"\bhow many|count|number of|list|show\b", t)) or \
           bool(re.search(r"\b(admission|join|upgrade|left|leaver|active)\b", t))
