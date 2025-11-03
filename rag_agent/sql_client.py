# Azure SQL exec
# Facts and dims used by queries are per  DWH tables and reporting views.
# We read from report.* for safety

from __future__ import annotations
import pyodbc
from typing import Iterable, Any, List, Dict, Tuple
from .config import get_settings

class AzureSQL:
    def __init__(self):
        s = get_settings().sql
        conn_str = (
            f"Driver={{{s.odbc_driver}}};"
            f"Server=tcp:{s.server},1433;"
            f"Database={s.database};"
            f"Uid={s.username};Pwd={s.password};"
            "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
        )
        self.conn = pyodbc.connect(conn_str)

    def query(self, sql: str, params: Iterable[Any] = ()) -> List[Tuple]:
        with self.conn.cursor() as cur:
            cur.execute(sql, list(params))
            rows = cur.fetchall()
        return [tuple(r) for r in rows]

    def query_dicts(self, sql: str, params: Iterable[Any] = ()) -> List[Dict[str, Any]]:
        with self.conn.cursor() as cur:
            cur.execute(sql, list(params))
            cols = [d[0] for d in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]
