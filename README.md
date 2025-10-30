# MS-Copilot-AgenticRAG-Evaluation

## Overview
- This project evaluates and compares **Microsoft Copilot (Power BI Copilot)** with a custom-built **Agentic Retrieval-Augmented Generation (RAG)** solution.  

- The objective is to measure response accuracy, contextual understanding, and reasoning quality when querying enterprise data.

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


- To be added in the final stage of RAG testing .