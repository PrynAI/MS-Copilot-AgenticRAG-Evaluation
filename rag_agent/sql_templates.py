 # safe query builder for KPIs

from __future__ import annotations
import re, calendar
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Dict, Any, List, Tuple, Optional

# Business mapping from repo:
# - Active membership counts use active_date_fk month. (Copilot validation guidance) 
# - Admissions('Join'), Upgrades('Upgrade') via membership_type_original.
# - Attrition via is_attrition=1 or membership_status_original IN ('Resigned','Deceased'). 

@dataclass(frozen=True)
class TimeWindow:
    start_fk: int   # YYYYMMDD as int
    end_fk: int     # exclusive upper bound YYYYMMDD as int

def month_bounds(year: int, month: int) -> TimeWindow:
    last = calendar.monthrange(year, month)[1]
    start_fk = int(f"{year:04d}{month:02d}01")
    end_fk = int(f"{year:04d}{month:02d}{last:02d}") + 1  # exclusive
    return TimeWindow(start_fk, end_fk)

def parse_time_window(text: str, today: Optional[date] = None) -> Tuple[str, TimeWindow]:
    t = text.lower()
    today = today or date.today()

    # explicit month-year like "november 2025", "oct 2025"
    m = re.search(r"(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec|january|february|march|april|june|july|august|september|october|november|december)\s+(\d{4})", t)
    if m:
        month_str, year_str = m.group(1), m.group(2)
        month_map = {
            "jan":1,"january":1,"feb":2,"february":2,"mar":3,"march":3,"apr":4,"april":4,"may":5,
            "jun":6,"june":6,"jul":7,"july":7,"aug":8,"august":8,"sep":9,"sept":9,"september":9,
            "oct":10,"october":10,"nov":11,"november":11,"dec":12,"december":12
        }
        mo = month_map[month_str[:3]]
        tw = month_bounds(int(year_str), mo)
        return ("month", tw)

    # this month / last month
    if "last month" in t:
        y = (today.replace(day=1) - timedelta(days=1)).year
        m = (today.replace(day=1) - timedelta(days=1)).month
        return ("month", month_bounds(y, m))
    if "this month" in t or "current month" in t:
        return ("month", month_bounds(today.year, today.month))

    # this year
    if "this year" in t or "current year" in t or re.search(r"\byear to date\b|\bytd\b", t):
        start_fk = int(f"{today.year:04d}0101")
        end_fk   = int(f"{today.year:04d}1231") + 1
        return ("year", TimeWindow(start_fk, end_fk))

    # default latest completed month (repo convention) :contentReference[oaicite:7]{index=7}
    lm = today.replace(day=1) - timedelta(days=1)
    return ("month", month_bounds(lm.year, lm.month))

@dataclass
class QueryPlan:
    sql: str
    params: Tuple[Any, ...]
    group_cols: List[str]

def build_kpi_sql(
    metric: str,           # 'active' | 'admissions' | 'upgrades' | 'left'
    granularity: str,      # 'month' or 'year' (affects default labels)
    window: TimeWindow,
    breakdown: Optional[str] = None    # 'month' | 'grade' | 'region' | 'gender'
) -> QueryPlan:
    """
    Returns a safe SELECT using report.* views. Counts are based on active_date_fk for month/year windows.
    """
    where = ["fm.active_date_fk >= ? AND fm.active_date_fk < ?"]
    params: List[Any] = [window.start_fk, window.end_fk]

    # filter by metric
    if metric == "active":
        where.append("fm.membership_status_original = 'Active'")
    elif metric == "admissions":
        where.append("fm.membership_type_original = 'Join'")
    elif metric == "upgrades":
        where.append("fm.membership_type_original = 'Upgrade'")
    elif metric == "left":
        where.append("(fm.is_attrition = 1 OR fm.membership_status_original IN ('Resigned','Deceased'))")
    else:
        raise ValueError(f"unknown metric: {metric}")

    joins: List[str] = ["JOIN report.dim_date d ON d.date_id = fm.active_date_fk"]
    select_cols: List[str] = []
    group_cols: List[str] = []

    if breakdown == "month":
        select_cols += ["d.year", "d.month_no", "d.mth_year AS label"]
        group_cols  += ["d.year", "d.month_no", "d.mth_year"]
        order_by = "ORDER BY d.year, d.month_no"
    elif breakdown == "grade":
        joins += ["JOIN report.dim_grade g ON g.id = fm.grade_fk"]
        select_cols += ["g.grade_name AS label"]
        group_cols  += ["g.grade_name"]
        order_by = "ORDER BY g.grade_name"
    elif breakdown == "region":
        joins += ["JOIN report.dim_hub h ON h.id = fm.hub_fk"]
        select_cols += ["h.regional_hub AS label"]
        group_cols  += ["h.regional_hub"]
        order_by = "ORDER BY h.regional_hub"
    elif breakdown == "gender":
        joins += ["JOIN report.dim_member m ON m.id = fm.member_fk"]
        select_cols += ["m.gender AS label"]
        group_cols  += ["m.gender"]
        order_by = "ORDER BY label"
    else:
        order_by = ""

    base = f"""
    SELECT
        {(", ".join(select_cols) + "," if select_cols else "")}
        COUNT(*) AS count
    FROM report.fact_membership fm
    {' '.join(joins)}
    WHERE {" AND ".join(where)}
    """
    if group_cols:
        base += f" GROUP BY {', '.join(group_cols)} {order_by}"
    return QueryPlan(sql=base.strip(), params=tuple(params), group_cols=group_cols)