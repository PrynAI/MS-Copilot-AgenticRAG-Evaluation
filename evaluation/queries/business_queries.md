# User Queries:

- Active membership this month
- How many active membership last month
- How many active membership this year 
- How many admission( joins) this month, or November 2025 
- How many admission( joins) last month, or October 2025 
- How many admission( joins) for this year 
- How many upgrades this month, or November 2025 
- How many upgrades last month, or Oct 2025 
- How many many members left this month, or November 2025 
- for all Above kpi's we need them also as per below rules
   - By month / by grade / by region / by gender


   | Query  | Needs SQL? | Fields and dims you already have | Search index used?| Status|
   
   | -------- | ---------- | -------- | -------------- | ------------------- |
| Active membership **this month**             | Yes                  | `dwh.fact_membership.active_date_fk`, `end_date_fk`, `membership_status_original`, `is_attrition`; join `report.dim_date` for [month start,end]                                                   | Optional for context/citations | OK. Use range filter on `active_date_fk<=month_end AND end_date_fk>=month_start` and exclude attrition.                            |
| Active membership **last month**             | Yes                  | Same as above                                                                                                                                                                                     | Optional                       | OK.                                                                                                                                |
| Active membership **this year**              | Yes                  | Same + year window from `report.dim_date`                                                                                                                                                         | Optional                       | OK.                                                                                                                                |
| Admissions (joins) **this month / Nov‑2025** | Yes                  | `is_admission=1`, `start_date_fk`; breakdowns via `dim_grade`, `dim_hub`, `dim_member.gender`, `dim_date`                                                                                         | Optional                       | OK.                                                                                                                                |
| Admissions **last month / Oct‑2025**         | Yes                  | Same                                                                                                                                                                                              | Optional                       | OK.                                                                                                                                |
| Admissions **this year**                     | Yes                  | Same                                                                                                                                                                                              | Optional                       | OK.                                                                                                                                |
| Upgrades **this month / Nov‑2025**           | Yes                  | `is_upgrade=1`, `start_date_fk`; dims as above                                                                                                                                                    | Optional                       | OK. Generator creates upgrade rows with flags.                                                                                     |
| Upgrades **last month / Oct‑2025**           | Yes                  | Same                                                                                                                                                                                              | Optional                       | OK.                                                                                                                                |
| **Members left this month / Nov‑2025**       | Yes, but **blocked** | Need an **attrition date**; today only `is_attrition=1` and a status label exist on join rows. `deleted_date_fk` is present but not populated; `end_date_fk` is always 31‑Dec (not a leave date). | Optional                       | **Gap.** Add and populate `deleted_date_fk` (or `attrition_date_fk`) when `membership_status_original IN ('Resigned','Deceased')`. |
