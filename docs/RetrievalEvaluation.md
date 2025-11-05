# Retrieval Evaluation — Azure AI Search RAG

## Scope

#### Measure retrieval quality of the current Azure AI Search index for 10 business queries. Compare three baselines:

    - Vector‑only

    - Hybrid (BM25 + vector, RRF)

    - Hybrid + Semantic rerank (same candidates, semantic re‑order)

#### Fixed settings: k_candidates=50, top=10. Metrics: Recall@10, MRR@10. We freeze the evaluation clock to a known data window and log run metadata.

## Inputs and snapshot


- Index: current membership RAG index (hybrid + semantic + integrated vectorization).
- Gold queries: eval/gold_queries.json (10 KPIs, with “by month/grade/region/gender” variants).
- v2 gold set source: pooled from Search with normalized month anchors and category filters (no SQL gold).
- Frozen clock: set EVAL_TODAY to a date inside the dataset window.

## Folder layout

```
eval/
  eval_common.py       # Search client + run metadata + eval clock (EVAL_TODAY)
  retrieval_modes.py   # vector-only | hybrid | hybrid+semantic
  normalize.py         # derives month anchor + category $filter
  metrics.py           # Recall@10, MRR@10
  build_goldset.py     # v2 pooled gold-set builder (uses Search + normalization)
  run_eval.py          # runs a baseline and writes CSV + .meta.json
  summarize.py         # prints macro deltas and per-query table
  gold_queries.json    # the 10 real queries
  runs/                # outputs

```

## What each script does

### eval_common.py
- Creates a Search client using .env. Emits per‑run metadata (mode, index, API version, timestamp). Provides get_eval_today() for a frozen clock.

### normalize.py

- Parses the query. Appends a month anchor token to the lexical text (e.g., 2025-10). Builds a category filter:

    - membership_status_original eq 'Active' for “active”

    - membership_type_original eq 'Join' for “admissions”

    - membership_type_original eq 'Upgrade' for “upgrades”

    - resigned/deceased for “left”
    - Returns (lex_text, vector_text, optional_filter).

### retrieval_modes.py

- Implements the three baselines. All call normalize_for_retrieval() and pass the optional $filter into Search. Keeps k_candidates=50, top=10.

### metrics.py

- Computes Recall@10 and MRR@10.

### build_goldset.py

- v2 gold‑set builder. Uses Search pooling with the same normalization rules to collect 20 relevant doc IDs per query. Writes goldset_v2.json.

### run_eval.py

- Loads a gold set, executes one baseline, writes per‑query metrics to CSV and macro metrics to a .meta.json.

### summarize.py

- Loads the three .meta.json files and prints macro deltas and a per‑query table

### Prerequisites

- .env with Azure Search endpoint, key, index, API version.
- Python 3.10+.
- Install requirements: pandas, numpy, tabulate, pydantic-settings, requests.

### How to run

#### Freeze the clock to a valid month in your dataset.

```
$env:EVAL_TODAY="2025-10-30"
```
### Build the v2 gold set (pooled from Search with normalization).

```
python -m eval.build_goldset --queries eval\gold_queries.json --out eval\goldset_v2.json --pool 200 --per_query 20

```

### Run the three baselines with fixed candidates and top‑k.

```
python -m eval.run_eval --mode vector   --gold eval\goldset_v2.json --out eval\runs\vector_v2.csv   --k_candidates 50 --top_k 10
python -m eval.run_eval --mode hybrid   --gold eval\goldset_v2.json --out eval\runs\hybrid_v2.csv   --k_candidates 50 --top_k 10
python -m eval.run_eval --mode semantic --gold eval\goldset_v2.json --out eval\runs\semantic_v2.csv --k_candidates 50 --top_k 10

```
### Summarize improvements.

```
python -m eval.summarize eval\runs\vector_v2.meta.json eval\runs\hybrid_v2.meta.json eval\runs\semantic_v2.meta.json

```

### Artifacts:

- Per‑query results: eval/runs/*.csv
- Run metadata: eval/runs/*.meta.json
(Contains mode, index, API version, k, top, timestamp.)

## v2 results

### Macro metrics

- Vector: Recall@10 = 0.029, MRR@10 = 0.157
- Hybrid: Recall@10 = 0.136, MRR@10 = 0.425
- Hybrid+Semantic: Recall@10 = 0.279, MRR@10 = 0.695

### Deltas

- Recall@10 Vector → Hybrid: 0.029 → 0.136
- Recall@10 Hybrid → Hybrid+Semantic: 0.136 → 0.279
- MRR@10 Vector → Hybrid: 0.157 → 0.425
- MRR@10 Hybrid → Hybrid+Semantic: 0.425 → 0.695

### Per‑query (excerpt, top‑10)

| qid | query                                           | gold | R@10 vec | R@10 hyb | R@10 sem | MRR vec | MRR hyb | MRR sem |
| --- | ----------------------------------------------- | ---- | -------- | -------- | -------- | ------- | ------- | ------- |
| Q1  | Active membership this month                    | 20   | 0.00     | 0.00     | 0.15     | 0.000   | 0.000   | 0.200   |
| Q2  | How many active membership last month by region | 20   | 0.00     | 0.20     | 0.15     | 0.000   | 0.333   | 1.000   |
| Q3  | How many active membership this year by grade   | 20   | 0.00     | 0.05     | 0.30     | 0.000   | 0.143   | 0.333   |
| Q4  | How many admission joins this month             | 20   | 0.05     | 0.05     | 0.35     | 0.100   | 1.000   | 1.000   |
| Q5  | How many admission joins November 2025          | 20   | 0.00     | 0.20     | 0.30     | 0.000   | 0.250   | 0.333   |
| Q6  | How many admission joins last month by grade    | 20   | 0.00     | 0.20     | 0.30     | 0.000   | 0.250   | 1.000   |
| Q9  | How many members left this month by gender      | 20   | 0.15     | 0.25     | 0.40     | 1.000   | 1.000   | 1.000   |



### Interpretation:

- Hybrid beats vector‑only.
- Semantic rerank improves both Recall@10 and MRR@10.
- MRR gains are strong; at least one relevant doc often ranks at position 1 after rerank.

### What changed from v1 to v2

#### Normalized queries:
- appended a month token (e.g., 2025‑10) into the lexical text to match chunk content.

#### Category filters:
- added $filter for status/type based on intent.
- Frozen clock: set EVAL_TODAY to stay inside the dataset window.

#### Aligned pooling:
- gold‑set pooling used the same normalization as evaluation runs.

##### These steps removed time‑window drift and reduced candidate noise. That produced the observed gains.

### Controls

- Keep index snapshot unchanged during a run.
- Log settings in .meta.json (mode, index, API version, k_candidates, top).
- Keep prompts out of retrieval eval (not used).
- Freeze the evaluation clock with EVAL_TODAY.

### Known limits

- Gold relevance is pooled from Search, not curated. It is approximate.
- With gold_size=20 and top=10, the theoretical max Recall@10 is 0.5.
- "Left by month" depends on how departures are represented in the text.
- Chunk‑level docs can split relevant text across multiple docIds.

### How to improve further

- Add month keys to the index (e.g., activeMonth, startMonth) and filter on them during retrieval and pooling. This reduces false positives in adjacent months.
- Increase gold_size or curate qrels manually for tighter ground truth.
- Report Recall@25 as an exploratory metric to estimate headroom while keeping the official baseline at top=10.
- Expand the query set and add more facet combinations (grade, region, gender) to reduce overfitting.

### Quick commands 

#### Rebuild v2 gold, run, and summarize:

```
$env:EVAL_TODAY="2025-10-30"
python -m eval.build_goldset --queries eval\gold_queries.json --out eval\goldset_v2.json --pool 200 --per_query 20

python -m eval.run_eval --mode vector   --gold eval\goldset_v2.json --out eval\runs\vector_v2.csv   --k_candidates 50 --top_k 10

python -m eval.run_eval --mode hybrid   --gold eval\goldset_v2.json --out eval\runs\hybrid_v2.csv   --k_candidates 50 --top_k 10

python -m eval.run_eval --mode semantic --gold eval\goldset_v2.json --out eval\runs\semantic_v2.csv --k_candidates 50 --top_k 10

python -m eval.summarize eval\runs\vector_v2.meta.json eval\runs\hybrid_v2.meta.json eval\runs\semantic_v2.meta.json

```