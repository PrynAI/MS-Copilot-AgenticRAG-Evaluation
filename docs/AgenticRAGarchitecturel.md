# Agentic RAG architecture (LangGraph + Azure AI Search + Azure SQL)

## Goal
- Answer membership analytics questions with grounded text and exact numbers. Compare outputs with Power BI Q&A and Copilot.

### High‑level design

#### Flow: Router → Retrieve → Tool‑call (SQL) → Synthesize.
- Default to retrieval. Call SQL when a metric or list is required. Merge sources with citations.

### Components

#### Data layer
- Azure SQL hosts facts and dims (dwh.*). Reporting views under report.* expose analytics tables and a RAG view for ingestion.
-  Synthetic data covers two years with joins, upgrades, rejoins, renewals, invoices, and payments.

#### Retrieval layer.

- Azure AI Search index membership‑rag‑idx stores chunked text and embeddings from report.vw_membership_rag.
- Hybrid queries run keyword + vector in parallel, merged with RRF, then semantic ranker reorders and can return extractive answers/captions.
- Use integrated vectorization: TextSplit → Azure OpenAI Embedding → chunkVector at index time.

#### Agent layer.
- LangGraph orchestrates nodes and state.
- Workflows define fixed paths.
- Agents select tools at runtime.
- We use a small, deterministic graph for reliability and debuggability.

#### Serving layer.
- FastAPI backend exposes /chat.
- Chainlit provides the UI
- Package as a container and deploy to Azure Container Apps with autoscale rules. CI/CD via GitHub Actions.

### Data contracts

#### Warehouse schemas:
- dwh.dim_*, dwh.fact_* per DDL.
#### Reporting views:
- report.* project facts and dims for BI and safe read access.
#### RAG view:
- report.vw_membership_rag emits human‑readable sentences plus filter fields; used by the indexer.
#### Generator:
- v7.2 seeds daily admissions, upgrades, rejoins, renewals, invoices, and payments with rules noted in docs.

### Retrieval configuration (Modern RAG)
#### Index fields:
- id, chunk, chunkVector.
- filterable fields like grade, hub, status, type, pricing, created_utc.
- Vector profile uses HNSW.
- Semantic config prioritizes chunk, content.
#### Ingestion:
- SQL data source → skillset → indexer. TextSplitSkill creates ~page‑sized chunks;
- AzureOpenAIEmbeddingSkill generates vectors; outputs map to chunk and chunkVector. This keeps query latency low and improves recall.
#### Hybrid + semantic query:
- Run keyword and vector branches together. RRF fuses results.
- Semantic ranker reranks and can return extractive answers.
- Use answers/captions only as supporting spans, not for math.

#### Integrated vectorization:
- Add a vectorizer and bind it to the vector field so the service can vectorize query text and index content with the same model.

### Agent graph (LangGraph)

#### State keys.
- user_query, intent, filters, time_window, search_hits, sql_result, citations, final_answer.

### Nodes.
#### Router: Classifies intent.
- If query asks for count, sum, average, top‑N, trend, or an explicit list → route to SQL.
- If query asks to explain, define, justify, or “status of …” → route to Search.
- If mixed → run Search + SQL.

#### Search Retrieve: 
- Build a hybrid semantic request with search and vectorQueries on chunkVector.
- Apply filters when present. Return top chunks and doc ids for citations.

#### Tool‑call (SQL):
- Parameterized SELECT … FROM report|dwh … WHERE … GROUP BY … only.
- Use report.* views for safety. Read‑only principal. No DDL/DML.

#### Synthesizer:
- Present numeric answer first from SQL.
- Add a compact table when useful.
- Attach 2–3 short snippets from Search with citations.
- State assumptions and data window.

#### Why this shape.
- It aligns with Azure AI Search guidance that hybrid + semantic improves relevance, while exact numerics must come from the database.

### System instruction (to pin in code)
```
You answer membership questions using two tools:

Azure AI Search on the membership‑rag‑idx index for grounding and citations.

Azure SQL (read‑only) for exact counts, lists, and trends from report.* and dwh.*.

Policy: decide intent {metric/list} vs {explain}. For any metric or list, run SQL and answer strictly from the SQL output. Use Search to quote 2–3 supporting snippets and cite their doc ids. If inputs are underspecified, assume the latest completed month and say so. Never fabricate. If tools cannot answer, return “I don’t know.” Return a short answer, an optional compact table, and citations.

```
#### Request lifecycle

- Normalize query: Extract filters, time window, and metric intent.
- Route: Choose Search, SQL, or both.
- Retrieve: Issue hybrid + semantic query. Collect top chunks and captions. 
- Compute: Run parameterized SQL on report.* and dwh.*.
- Synthesize: Combine numbers with grounded snippets. Add citations.
- Log: Persist decisions, prompts, queries, and latencies for evaluation.


#### Defaults, guardrails, and security

- Defaults. If the user gives no dates, use the latest completed month. If no grain is given, return totals plus the top 5 breakdown.

- Guardrails. Whitelist SQL templates. Enforce read‑only principal. Block free‑form SQL. Never compute numbers from semantic answers. 

- Secrets. Store keys in Key Vault or dev secrets. Assign db_datareader to the search identity and the agent. No secrets in prompts or logs

#### Performance targets and ops

- Latency. <3 s for cached queries. <8 s for new queries. Use response caching for SQL and retrieval results keyed by normalized filters.

- Scale. Run as containers on Azure Container Apps. Use autoscale rules on HTTP concurrency and CPU.

- Observability. Log tool I/O, retrieval metrics, and answer diffs vs Power BI for analysis.

#### Evaluation plan

- Retrieval. Track hit@k and citation overlap for test prompts. Hybrid + semantic should outperform pure vector or pure keyword.
- Answer quality. Compare agent numerics vs Power BI visuals vs MS-Copilot responses for the same filters. Record deltas and explanations.

#### Deliverables

- Azure SQL schemas and synthetic data populated. Views created.
- Azure AI Search index with integrated vectorization over report.vw_membership_rag.
- LangGraph agent with Router, Retrieve, SQL tool, Synthesizer. 
docs.langchain.com
- FastAPI service and Chainlit UI deployed to Azure Container Apps with CI/CD