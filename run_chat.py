 # CLI to test queries

from __future__ import annotations
from rag_agent.graph import build_graph

if __name__ == "__main__":
    graph = build_graph()
    print("LangGraph Agent. Ctrl+C to exit.")
    while True:
        try:
            q = input("\n> ")
            state = {"user_query": q}
            out = graph.invoke(state)
            print("\n" + out.get("answer", "(no answer)"))
        except KeyboardInterrupt:
            print("\nbye")
            break
