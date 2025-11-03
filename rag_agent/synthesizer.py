# LLM to compose final answer


from __future__ import annotations
from typing import List, Dict, Any, Tuple
from openai import AzureOpenAI
from .config import get_settings

_sys = (
"You answer membership analytics using two tools: SQL for exact numbers and Azure AI Search for citations. "
"Never fabricate numbers. Use the provided SQL results as the numeric source of truth. "
"Keep the answer concise. If a table is provided, summarize it briefly."
)

class Synthesizer:
    def __init__(self):
        s = get_settings().openai
        self.client = AzureOpenAI(
            api_key=s.api_key,
            api_version=s.api_version,
            azure_endpoint=s.endpoint
        )
        self.deployment = s.chat_deployment

    def compose(self, user_query: str, sql_rows: List[Dict[str, Any]], citations: List[Tuple[str,str]]) -> str:
        # Build a compact textual table for the model
        if sql_rows and isinstance(sql_rows[0], dict) and "count" in sql_rows[0]:
            headers = [k for k in sql_rows[0].keys()]
            lines = [", ".join(headers)]
            for r in sql_rows:
                lines.append(", ".join(str(r[h]) for h in headers))
            table_csv = "\n".join(lines)
        else:
            table_csv = "count\n0"

        cites = "\n".join([f"- {doc}: {snippet}" for doc, snippet in citations])

        prompt = f"""
User query:
{user_query}

SQL results (CSV):
{table_csv}

Citations (snippets from Azure AI Search):
{cites}

Rules:
- Report the number(s) directly from SQL results.
- If multiple rows exist, summarize patterns and mention the grouping column name.
- End with “Sources: Azure SQL, Azure AI Search”.
"""
        resp = self.client.chat.completions.create(
            model=self.deployment,
            messages=[
                {"role": "system", "content": _sys},
                {"role": "user", "content": prompt}
            ],
            # temperature=0.2,
            # max_tokens=350,
        )
        return resp.choices[0].message.content.strip()
