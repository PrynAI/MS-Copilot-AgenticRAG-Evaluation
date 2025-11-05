from __future__ import annotations
import sys, json, pandas as pd
from pathlib import Path

def load(meta_path):
    meta = json.load(open(meta_path, "r", encoding="utf-8"))
    csv_path = meta_path.replace(".meta.json", ".csv")
    df = pd.read_csv(csv_path)
    return meta, df

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("usage: python -m eval.summarize <vector.meta.json> <hybrid.meta.json> <semantic.meta.json>")
        sys.exit(1)

    meta_vec, df_vec = load(sys.argv[1])
    meta_hyb, df_hyb = load(sys.argv[2])
    meta_sem, df_sem = load(sys.argv[3])

    print("\nMacro metrics")
    for name, meta in [("Vector", meta_vec), ("Hybrid", meta_hyb), ("Hybrid+Semantic", meta_sem)]:
        print(f"{name}: Recall@10={meta['macro_recall_at_10']:.3f}  MRR@10={meta['macro_mrr_at_10']:.3f}")

    print("\nDeltas")
    print(f"Recall@10  Vector→Hybrid: {meta_vec['macro_recall_at_10']:.3f} → {meta_hyb['macro_recall_at_10']:.3f}")
    print(f"Recall@10  Hybrid→Hybrid+Semantic: {meta_hyb['macro_recall_at_10']:.3f} → {meta_sem['macro_recall_at_10']:.3f}")
    print(f"MRR@10     Vector→Hybrid: {meta_vec['macro_mrr_at_10']:.3f} → {meta_hyb['macro_mrr_at_10']:.3f}")
    print(f"MRR@10     Hybrid→Hybrid+Semantic: {meta_hyb['macro_mrr_at_10']:.3f} → {meta_sem['macro_mrr_at_10']:.3f}")

    # per-query comparison table
    df = df_vec.merge(df_hyb, on=["qid","query"], suffixes=("_vec","_hyb")).merge(
        df_sem, on=["qid","query"]
    )
    df.rename(columns={"recall_at_10":"recall_at_10_sem","mrr_at_10":"mrr_at_10_sem"}, inplace=True)
    cols = ["qid","query","gold_size","recall_at_10_vec","recall_at_10_hyb","recall_at_10_sem","mrr_at_10_vec","mrr_at_10_hyb","mrr_at_10_sem"]
    print("\nPer-query:")
    print(df[cols].to_string(index=False, max_colwidth=60))