# LangGraph RAG Agent (Azure AI Search + Azure SQL)

## Purpose

- Answer membership analytics with exact numbers from Azure SQL and grounded snippets from Azure AI Search. This agent is Stage 3 of the evaluation project comparing Q&A, Copilot, and Agentic RAG

### What the agent does

- Routes a user query to SQL when a metric or list is requested.
- Retrieves supporting context from Azure AI Search using hybrid + semantic.
- Synthesizes a short answer with citations.

### Architecture summary

#### Nodes:
- router → retrieve → compute → synthesize. State contains intent, metric, time window, breakdown, search_hits, sql_rows, citations, answer. The graph is built with LangGraph and compiled as a deterministic workflow.

#### Data lineage.
- Warehouse facts/dims under dwh.*; reporting views under report.*; ingestion view for RAG is report.vw_membership_rag. Synthetic data generator enforces membership rules and flags

#### Retrieval.
- Azure AI Search index membership‑rag‑idx, hybrid + semantic with an Azure OpenAI vectorizer bound to the HNSW profile; query uses vectorQueries: [{kind:"text"}] plus lexical search and semantic reranking.

#### KPI scope.
- Queries and required breakdowns are fixed in the project brief. Attrition by month needs an attrition date; current dataset lacks a reliable leave date.

#### Repository layout

```
rag_agent/
  config.py            # loads secrets from .env via pydantic-settings
  search_client.py     # Azure AI Search hybrid+semantic
  sql_client.py        # Azure SQL read-only execution
  sql_templates.py     # safe KPI SQL generator
  intent_router.py     # metric/list detection + breakdowns
  synthesizer.py       # LLM composition (Azure OpenAI)
  graph.py             # LangGraph assembly
run_chat.py            # CLI for local testing

```
#### Prerequisites

- Windows 11, Python 3.11.
- ODBC Driver 18 for SQL Server.
- Azure SQL database seeded with the project’s DWH and views.
- Azure AI Search index and indexer configured for Modern RAG (hybrid + semantic + integrated vectorization).

#### Configuration

- Create .env in the repo root. The code reads these with pydantic‑settings; do not hardcode secrets.

```
AZURE_OPENAI_ENDPOINT=...
AZURE_OPENAI_API_KEY=...
AZURE_OPENAI_API_VERSION=2024-08-01-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-5-mini

AZURE_SEARCH_ENDPOINT=...
AZURE_SEARCH_API_KEY=...
AZURE_SEARCH_INDEX=membership-rag-idx
AZURE_SEARCH_API_VERSION=2025-09-01

AZURE_SQL_SERVER=...
AZURE_SQL_DATABASE=copilotrag
AZURE_SQL_USERNAME=...
AZURE_SQL_PASSWORD=...
AZURE_SQL_ODBC_DRIVER=ODBC Driver 18 for SQL Server
```
- The search index name and ingestion view align with the retrieval configuration and RAG ingestion view.

#### Install and run

```
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python .\run_chat.py

```
- run_chat.py starts an interactive CLI and invokes the compiled graph.

#### Example prompts (from the KPI brief):

- Active membership this month
- How many active membership last month by region
- How many admission joins this year by grade
- How many upgrades in September 2025
- How many members left last month by gender

### How it works

#### Router

- Rule‑based detection maps the query to a metric/list or explain intent, identifies the KPI (active | admissions | upgrades | left), parses time (month, last month, explicit “Nov 2025”, or year), and optional breakdown (month, grade, region, gender). Defaults to the latest completed month when unspecified.

#### Retrieval

- Executes a hybrid + semantic search with captions and optional answers; returns top chunks and snippets for citation. Do not use retrieval to compute numbers.

### SQL tool

- Builds safe, parameterized SQL over report.* views with date ranges on active_date_fk. Breakdown joins to dim_date, dim_grade, dim_hub, or dim_member as needed. Returns rows for the synthesizer.

- The KPI SQL generator implements these mappings: active → membership_status_original='Active'; admissions → 'Join'; upgrades → 'Upgrade'; left → attrition flags (limited; see “Limits”).

### Synthesis

- LLM composes a concise answer from SQL rows and appends 2–3 snippets as citations. The system prompt enforces “numbers from SQL only.

### Data sources and ingestion

- Warehouse tables and generators define facts/dims and produce two years of activity with business rules.
- report.vw_membership_rag emits readable content and filter fields for ingestion to the search index.
- Search index uses integrated vectorization, TextSplit, and Azure OpenAI Embedding in the indexer.

### Limits and known gaps
- "Members left this month" requires a populated leave/attrition date; current dataset does not persist a reliable monthly attrition date. Treat the KPI as Not available or compute at a coarser grain until deleted_date_fk or an attrition_date_fk is filled.
- Do not compute totals from semantic answers. Always use SQL for numerics.

### Troubleshooting

- Missing env vars → ValidationError on startup. Ensure .env exists and names match. The config loader reads from .env
- ODBC error → install ODBC Driver 18 and verify server firewall. Warehouse connection and table names come from the project scripts.
- Search 401/403 → validate Search endpoint, API key, and index name membership‑rag‑idx

### Security

- Keep .env out of source control.
- Use a read‑only SQL principal; agent never writes. Views under report.* are the safe surface.
- Do not log secrets. See data prep notes for current environment and access boundaries.

### Next steps

- Wrap the agent behind FastAPI and Chainlit per project plan.
- Add caching and richer filter parsing.
- Populate attrition date to fully support “left by month.”

