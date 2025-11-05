from __future__ import annotations
import json, argparse
from typing import Dict, List, Set, Tuple
from rag_agent.sql_templates import parse_time_window
from rag_agent.intent_router import detect_metric
from .eval_common import SearchClient
from .normalize import normalize_for_retrieval

def time_anchor_from_query(q: str) -> str:
    # e.g., "2025-11" for Nov-2025; for "this year" anchor "2025"
    granularity, tw = parse_time_window(q)
    if granularity == "month":
        y = tw.start_fk // 10000
        m = (tw.start_fk // 100) % 100
        return f"{y:04d}-{m:02d}"
    else:
        y = tw.start_fk // 10000
        return f"{y:04d}"

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

def pool_gold_for_query(qid: str, query: str, pool: int = 200, per_query: int = 20) -> List[str]:
    lex, vec, filt = normalize_for_retrieval(query)
    body = {"search": lex, "top": pool, "select": "id,content"}
    if filt: body["filter"] = filt
    res = SearchClient().post(body).get("value", [])
    return [r["id"] for r in res][:per_query]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queries", required=True, help="path to gold_queries.json")
    ap.add_argument("--out", required=True, help="path to write goldset.json")
    ap.add_argument("--pool", type=int, default=200)
    ap.add_argument("--per_query", type=int, default=20)
    args = ap.parse_args()

    with open(args.queries, "r", encoding="utf-8") as f:
        queries = json.load(f)

    gold: Dict[str, Dict[str, List[str]]] = {}
    for item in queries:
        qid, qtext = item["id"], item["query"]
        ids = pool_gold_for_query(qid, qtext, pool=args.pool, per_query=args.per_query)
        gold[qid] = {"query": qtext, "relevant_doc_ids": ids, "scorable": bool(ids)}

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(gold, f, indent=2)

if __name__ == "__main__":
    main()