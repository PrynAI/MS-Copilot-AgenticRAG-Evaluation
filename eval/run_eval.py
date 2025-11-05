from __future__ import annotations
import json, argparse, csv, pathlib
from typing import Dict, List, Set
from .metrics import recall_at_k, mrr_at_k
from .retrieval_modes import vector_only, hybrid_rrf, hybrid_semantic
from .eval_common import run_metadata

def evaluate(mode_fn, gold_path: str, out_csv: str, k_candidates: int = 50, top_k: int = 10):
    gold = json.load(open(gold_path, "r", encoding="utf-8"))
    rows = []
    macro_recall, macro_mrr, n = 0.0, 0.0, 0

    for qid, obj in gold.items():
        if not obj.get("scorable", True):
            continue
        qtext: str = obj["query"]
        rel: Set[str] = set(obj["relevant_doc_ids"])

        pred: List[str] = mode_fn(qtext, k_candidates=k_candidates, top_k=top_k)
        r = recall_at_k(pred, rel, k=top_k)
        m = mrr_at_k(pred, rel, k=top_k)

        rows.append({"qid": qid, "query": qtext, "recall_at_10": r, "mrr_at_10": m,
                     "gold_size": len(rel)})
        macro_recall += r
        macro_mrr += m
        n += 1

    pathlib.Path(out_csv).parent.mkdir(parents=True, exist_ok=True)
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["qid", "query", "gold_size", "recall_at_10", "mrr_at_10"])
        w.writeheader()
        for r in rows:
            w.writerow(r)

    meta = run_metadata(mode_fn.__name__, k_candidates, top_k)
    meta["macro_recall_at_10"] = macro_recall / max(1, n)
    meta["macro_mrr_at_10"] = macro_mrr / max(1, n)
    meta_path = out_csv.replace(".csv", ".meta.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["vector","hybrid","semantic"], required=True)
    ap.add_argument("--gold", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--k_candidates", type=int, default=50)
    ap.add_argument("--top_k", type=int, default=10)
    args = ap.parse_args()

    if args.mode == "vector":
        fn = vector_only
    elif args.mode == "hybrid":
        fn = hybrid_rrf
    else:
        fn = hybrid_semantic

    evaluate(fn, gold_path=args.gold, out_csv=args.out, k_candidates=args.k_candidates, top_k=args.top_k)

if __name__ == "__main__":
    main()