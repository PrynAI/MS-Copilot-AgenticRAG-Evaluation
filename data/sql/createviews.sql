/* ============================================================================
MS-Copilot-AgenticRAG-Evaluation : Create report.* views (pass-through)
Target: Azure SQL Database
Notes:
 - Idempotent: uses CREATE OR ALTER VIEW so you can re-run safely.
 - Preserves original column names (including spaces/typos) via SELECT *.
============================================================================ */

-- Ensure [report] schema exists (your table script already creates it, but this
-- keeps the view script self-contained).
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'report')
    EXEC('CREATE SCHEMA [report] AUTHORIZATION [dbo]');
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Dimension & Fact pass-throughs -------------------------------- */

CREATE OR ALTER VIEW [report].[dim_date] AS
SELECT * FROM [dwh].[dim_date];
GO

CREATE OR ALTER VIEW [report].[dim_grade] AS
SELECT * FROM [dwh].[dim_grade];
GO

CREATE OR ALTER VIEW [report].[dim_hub] AS
SELECT * FROM [dwh].[dim_hub];
GO

CREATE OR ALTER VIEW [report].[dim_member] AS
SELECT * FROM [dwh].[dim_member];
GO

CREATE OR ALTER VIEW [report].[dim_product] AS
SELECT * FROM [dwh].[dim_product];
GO

CREATE OR ALTER VIEW [report].[dim_organisation] AS
SELECT * FROM [dwh].[dim_organisation];
GO

CREATE OR ALTER VIEW [report].[fact_membership] AS
SELECT * FROM [dwh].[fact_membership];
GO

CREATE OR ALTER VIEW [report].[fact_payment] AS
SELECT * FROM [dwh].[fact_payment];
GO

CREATE OR ALTER VIEW [report].[fact_renewal] AS
SELECT * FROM [dwh].[fact_renewal];
GO

CREATE OR ALTER VIEW [report].[fact_invoice] AS
SELECT * FROM [dwh].[fact_invoice];
GO
