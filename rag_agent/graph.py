# LangGraph assembly

from __future__ import annotations
from typing import TypedDict, List, Dict, Any, Tuple
from langgraph.graph import StateGraph, END
from .search_client import AzureAISearch, extract_citations
from .sql_client import AzureSQL
from .sql_templates import parse_time_window, build_kpi_sql
from .intent_router import detect_metric, detect_breakdown, is_metric_or_list_query
from .synthesizer import Synthesizer

# ---- Shared state ----
class AgentState(TypedDict, total=False):
    user_query: str
    intent: str           # 'metrics' or 'explain'
    metric: str           # 'active'|'admissions'|'upgrades'|'left'
    granularity: str      # 'month' or 'year'
    breakdown: str | None
    time_start_fk: int
    time_end_fk: int
    search_hits: Dict[str, Any]
    sql_rows: List[Dict[str, Any]]
    citations: List[Tuple[str,str]]
    answer: str

search = AzureAISearch()
sql = AzureSQL()
synth = Synthesizer()

# ---- Nodes ----
def router_node(state: AgentState) -> AgentState:
    q = state["user_query"]
    if is_metric_or_list_query(q):
        kind, tw = parse_time_window(q)
        metric = detect_metric(q)
        breakdown = detect_breakdown(q)
        state.update({
            "intent": "metrics",
            "metric": metric,
            "granularity": kind,
            "breakdown": breakdown,
            "time_start_fk": tw.start_fk,
            "time_end_fk": tw.end_fk
        })
    else:
        state.update({"intent": "explain"})
    return state

def search_node(state: AgentState) -> AgentState:
    r = search.hybrid_semantic(
        query=state["user_query"],
        top=5,
        select="id,chunk,content,membership_status_original,membership_type_original,special_pricing_reason"
    )
    state["search_hits"] = r
    state["citations"] = extract_citations(r, max_snippets=3)
    return state

def sql_node(state: AgentState) -> AgentState:
    qplan = build_kpi_sql(
        metric=state["metric"],
        granularity=state["granularity"],
        window=type("TW", (), {"start_fk": state["time_start_fk"], "end_fk": state["time_end_fk"]}),
        breakdown=state.get("breakdown")
    )
    rows = sql.query_dicts(qplan.sql, qplan.params)
    state["sql_rows"] = rows
    return state

def synth_node(state: AgentState) -> AgentState:
    ans = synth.compose(
        user_query=state["user_query"],
        sql_rows=state.get("sql_rows", []),
        citations=state.get("citations", [])
    )
    state["answer"] = ans
    return state

# ---- Graph ----
def build_graph():
    g = StateGraph(AgentState)
    g.add_node("router", router_node)
    g.add_node("retrieve", search_node)
    g.add_node("compute", sql_node)
    g.add_node("synthesize", synth_node)

    g.set_entry_point("router")

    def route_logic(state: AgentState):
        if state.get("intent") == "metrics":
            # run both: SQL for numbers + Search for citations
            return "retrieve"
        else:
            # explanation-only path uses Search only, but keep same flow for simplicity
            return "retrieve"

    g.add_conditional_edges("router", route_logic, {"retrieve": "retrieve"})

    # If metrics, also compute SQL, then synth
    def after_retrieve(state: AgentState):
        if state.get("intent") == "metrics":
            return "compute"
        return "synthesize"

    g.add_conditional_edges("retrieve", after_retrieve, {"compute": "compute", "synthesize": "synthesize"})
    g.add_edge("compute", "synthesize")
    g.add_edge("synthesize", END)

    return g.compile()
