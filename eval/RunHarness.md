# from repo root, venv active, .env configured

# 1) Build gold set (20 relevant doc IDs per query from the current index)
python -m eval.build_goldset --queries eval\gold_queries.json --out eval\goldset_v1.json --pool 200 --per_query 20

# 2) Baseline runs (k_candidates=50, top=10)
python -m eval.run_eval --mode vector  --gold eval\goldset_v1.json --out eval\runs\vector_v1.csv    --k_candidates 50 --top_k 10
python -m eval.run_eval --mode hybrid  --gold eval\goldset_v1.json --out eval\runs\hybrid_v1.csv    --k_candidates 50 --top_k 10
python -m eval.run_eval --mode semantic --gold eval\goldset_v1.json --out eval\runs\semantic_v1.csv --k_candidates 50 --top_k 10

# 3) Summarize improvements
python -m eval.summarize eval\runs\vector_v1.meta.json eval\runs\hybrid_v1.meta.json eval\runs\semantic_v1.meta.json