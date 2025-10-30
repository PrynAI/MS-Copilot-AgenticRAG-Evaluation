# MS-Copilot-AgenticRAG-Evaluation

## Overview
This project evaluates and compares **Microsoft Copilot (Power BI Copilot)** with a custom-built **Agentic Retrieval-Augmented Generation (RAG)** solution.  
The objective is to measure response accuracy, contextual understanding, and reasoning quality when querying enterprise data.

---

## Objectives
- Assess the accuracy of natural language responses across three approaches:
  1. Power BI Inbuilt Q&A  
  2. Power BI Copilot (Fabric Enabled)  
  3. Custom Agentic RAG Solution  
- Establish a structured evaluation framework for enterprise data intelligence.
- Present end-to-end architecture, metrics, and findings for organizational demo and assessment.

---

## System Architecture

### Data Layer
- **Azure SQL Database** hosts fact and dimension tables.
- Synthetic data generated dynamically for the last two years.
- SQL Views expose analytical data models for Power BI and RAG components.

### Power BI Layer
- Create semantic models and dashboards from SQL Views.
- Evaluate **Power BI Q&A** and **Copilot** for query handling and result accuracy.

### RAG Layer
- **Framework:** LangChain / LangGraph  
- **LLMs:** OpenAI GPT models (LLM, embedding, moderation)  
- **Vector Store:** Azure AI Search (Standard SKU)  
- **Backend:** FastAPI  
- **UI:** Chainlit  
- **Deployment:** Azure Container Apps  
- **CI/CD:** GitHub Actions  
- **Agent Hosting:** LangGraph Cloud  

---

## Implementation Stages

| Stage | Description |
|--------|--------------|
| **Stage 1** | Evaluate results using Power BI Q&A. |
| **Stage 2** | Enable Microsoft Fabric and test with Power BI Copilot. |
| **Stage 3** | Build and deploy Agentic RAG solution using Azure SQL, LangGraph, and OpenAI models. |
| **Stage 4** | Compare all three systems using consistent test queries and metrics. |

---

## Evaluation Metrics

| Metric | Description |
|---------|-------------|
| **Accuracy** | Alignment between query intent and retrieved results. |
| **Relevance** | Degree to which responses match business context. |
| **Latency** | Response generation time per query. |
| **Interpretability** | Transparency of model reasoning or data source. |
| **Consistency** | Repeatability of results under identical inputs. |

---

## Scope and Constraints
- Short-term memory (session-level) only.  
- No authentication or user profiles.  
- No long-term memory persistence.  
- Test environment; read-only data access.  
- Focus: query comprehension, reasoning, and grounded accuracy.

---

## Technology Stack

| Layer | Technology |
|--------|-------------|
| Data | Azure SQL Database |
| Analytics | Power BI, Power BI Copilot |
| LLM Framework | LangChain / LangGraph |
| Model | OpenAI GPT |
| Embeddings | OpenAI Embeddings |
| Search | Azure AI Search |
| Backend | FastAPI |
| UI | Chainlit |
| Hosting | Azure Container Apps |
| CI/CD | GitHub Actions |
| Agent Platform | LangGraph Cloud |

---

## Deployment Overview

1. **Data Preparation:**  
   Generate synthetic data and create SQL Views.  

2. **Semantic Model Creation:**  
   Build Power BI dataset with relationships.  

3. **Containerized RAG System:**  
   - Deploy FastAPI and Chainlit via Azure Container Apps.  
   - Auto-deploy via GitHub Actions (OIDC Authentication).  

4. **Agent Deployment:**  
   Deploy RAG Agent to LangGraph Cloud.  

---

## Evaluation Process
1. Execute predefined test queries across all three systems.  
2. Capture query, response, and latency results.  
3. Score each system on Accuracy, Relevance, and Consistency.  
4. Document observations and visualize results in Power BI.

---

## Repository Structure


MS-Copilot-AgenticRAG-Evaluation/
├── data/
│   ├── sql/
│   │   ├── ddl/                  # table creation scripts
│   │   ├── views/                # view definitions
│   │   └── seeds/                # small seed CSVs
│   └── synthetic/
│       ├── schema_config.yaml    # column types, value ranges, enums
│       └── generated/            # large generated data (gitignored)
├── src/
│   ├── data_generation/
│   │   └── generate_synthetic_data.py
│   ├── fastapi_gateway/
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── api/
│   │   │   ├── services/
│   │   │   ├── models/
│   │   │   └── settings.py
│   │   └── requirements.txt
│   ├── chainlit_ui/
│   │   ├── app.py                # UI for RAG testing
│   │   ├── chainlit.md           # help and prompts
│   │   └── .chainlit/config.toml
│   └── langgraph_agent/
│       ├── agent.py
│       ├── graph.py
│       ├── tools/
│       ├── retrieval/
│       │   ├── azure_ai_search.py
│       │   └── sql_retriever.py
│       └── prompts/
│           ├── system.txt
│           └── moderation.txt
├── evaluation/
│   ├── queries/
│   │   ├── business_queries.csv  # canonical test questions
│   │   └── instructions.md       # how to run manual tests in UI
│   ├── scoring/
│   │   ├── metrics.py            # optional auto scoring utilities
│   │   └── schema.json           # result schema
│   └── results/
│       ├── ui_logs/              # Chainlit session logs
│       ├── api_logs/             # FastAPI request logs
│       └── comparisons/          # exports comparing Copilot vs RAG
├── powerbi/
│   ├── datasets/
│   │   └── semantic_model.pbip   # or dataset definition
│   ├── dashboards/
│   │   └── reports.pbix          # demo dashboard
│   └── qna/
│       └── phrasing.yaml         # synonyms and phrasing for Q&A
├── infrastructure/
│   ├── docker/
│   │   ├── Dockerfile.fastapi
│   │   └── Dockerfile.chainlit
│   ├── azure/
│   │   ├── aca.yaml              # Azure Container Apps manifests
│   │   ├── ai-search.bicep       # Azure AI Search infra
│   │   └── sql-setup.sql         # roles, indexes
│   └── scripts/
│       ├── seed_db.py
│       ├── ingest_to_search.py
│       └── deploy_aca.sh
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── build_deploy_fastapi.yml
│       └── build_deploy_chainlit.yml
├── configs/
│   ├── env.example               # required env vars
│   └── appsettings.yaml
├── docs/
│   ├── SRS_RAG_Evaluation_Project.docx
│   ├── Architecture_Diagram.png
│   └── Presentation_Deck.pptx
├── scripts/
│   ├── load_sql_views.py
│   ├── run_local.sh
│   └── make_sample_data.sh
├── results/                      # optional release-ready exports
├── README.md
├── requirements.txt
├── .gitignore
└── LICENSE