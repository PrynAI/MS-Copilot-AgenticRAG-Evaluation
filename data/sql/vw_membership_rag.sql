CREATE OR ALTER VIEW report.vw_membership_rag AS
SELECT
  -- stable key: member + start + grade
  CAST(fm.member_fk AS varchar(20)) + '-' +
  CAST(fm.start_date_fk AS varchar(8)) + '-' +
  CAST(fm.grade_fk AS varchar(10))              AS doc_id,

  -- filters we’ll keep
  fm.member_fk, fm.grade_fk, fm.hub_fk,
  fm.active_date_fk, fm.end_date_fk,
  fm.membership_status_original,
  fm.membership_type_original,
  fm.special_pricing_reason,

  -- human‑readable text for chunking/embedding
  CONCAT(
    'Member ', ISNULL(fm.membership_number,''), ' ',
    ISNULL(fm.membership_name,''), '. ',
    'Grade: ', ISNULL(g.grade_name,''), '. ',
    'Hub: ', ISNULL(h.country_name,''), '/', ISNULL(h.local_hub,''), '. ',
    'Status: ', ISNULL(fm.membership_status_original,''), ' ',
    ISNULL(fm.membership_type_original,''), '. ',
    'Active: ', CONVERT(varchar(10), CONVERT(date, CONVERT(varchar(8), fm.active_date_fk), 112), 120),
    ' End: ', CONVERT(varchar(10), CONVERT(date, CONVERT(varchar(8), fm.end_date_fk), 112), 120), '.'
  ) AS content
FROM dwh.fact_membership fm
LEFT JOIN dwh.dim_grade g ON g.id = fm.grade_fk
LEFT JOIN dwh.dim_hub   h ON h.id = fm.hub_fk;
GO