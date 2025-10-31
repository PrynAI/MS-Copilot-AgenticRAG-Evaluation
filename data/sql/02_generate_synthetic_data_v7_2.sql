
/*
================================================================================
MS-Copilot-AgenticRAG-Evaluation : Synthetic Data Generator (T-SQL)  v7.2
Target: Azure SQL Database

Hotfixes on top of v7.1:
- FIX-004: In #StatusPick and #PricingPick, outer SELECT now references the correct
           alias from the derived table (z/p), not an out-of-scope alias (a).
- FIX-005: Added [invoice_id] to #Admissions so later updates/selects compile.
Other v7.1 fixes retained (CTE usage, CASE...END, OUTPUT scope), and all
subscription rules remain applied.
================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET DATEFIRST 7;

/* ----------------------------------------------------------------------------
Parameters
---------------------------------------------------------------------------- */
DECLARE @EndDate date = CONVERT(date, GETDATE());
-- DECLARE @EndDate date = '2025-10-30';  -- Uncomment for reproducible run
DECLARE @StartDate date = DATEADD(year, -2, @EndDate);

DECLARE @SeedBaseWeekday int = 20;
DECLARE @SeedBaseWeekend int = 6;
DECLARE @BaseCurrencyFk int = 5;

/* ----------------------------------------------------------------------------
Run marker
---------------------------------------------------------------------------- */
IF OBJECT_ID('dwh.__synthetic_run') IS NULL
BEGIN
    CREATE TABLE dwh.__synthetic_run (
        run_id     int IDENTITY(1,1) PRIMARY KEY,
        start_date date NOT NULL,
        end_date   date NOT NULL,
        created_at datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

IF EXISTS (SELECT 1 FROM dwh.__synthetic_run WHERE start_date = @StartDate AND end_date = @EndDate)
BEGIN
    PRINT 'Synthetic data for this window already exists. Skipping.';
    RETURN;
END;

/* ----------------------------------------------------------------------------
Tally (prepare numbers source) — use the CTE to avoid Msg 422
---------------------------------------------------------------------------- */
;WITH N AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT COUNT(*) AS __tally_prepared FROM N OPTION (MAXDOP 1);

/* ----------------------------------------------------------------------------
1) dim_date
---------------------------------------------------------------------------- */
;WITH Dates AS (
    SELECT d = @StartDate
    UNION ALL
    SELECT DATEADD(day, 1, d) FROM Dates WHERE DATEADD(day, 1, d) <= @EndDate
)
INSERT INTO dwh.dim_date
(
    date_id, [date], [year], month_no, month_name, mth, mth_year, mth_year_no,
    [day], weekday_no, weekday_name, [quarter],
    years_from_today, months_from_today, weeks_from_today, days_from_today,
    week_no, weekend_date, past_date, renewal_month_sort, is_completed_month,
    end_of_month, is_end_of_month, qtr_year
)
SELECT
    CONVERT(char(8), d, 112),
    CAST(d AS datetime),
    DATEPART(year, d),
    DATEPART(month, d),
    DATENAME(month, d),
    LEFT(DATENAME(month, d), 3),
    CONCAT(LEFT(DATENAME(month, d), 3), '-', RIGHT(CONVERT(varchar(4), DATEPART(year, d)), 2)),
    (DATEPART(year, d) * 100) + DATEPART(month, d),
    DATEPART(day, d),
    ((DATEPART(WEEKDAY, d) + @@DATEFIRST + 5) % 7) + 1,
    DATENAME(weekday, d),
    DATEPART(quarter, d),
    DATEDIFF(year, d, GETDATE()),
    DATEDIFF(month, d, GETDATE()),
    DATEDIFF(week, d, GETDATE()),
    DATEDIFF(day, d, GETDATE()),
    DATEPART(week, d),
    DATEADD(day, 7 - ((DATEPART(WEEKDAY, d) + @@DATEFIRST - 1) % 7), CAST(d AS datetime)),
    CASE WHEN d < CAST(GETDATE() AS date) THEN 1 ELSE 0 END,
    DATEPART(month, d),
    0,
    EOMONTH(d),
    CASE WHEN d = EOMONTH(d) THEN 1 ELSE 0 END,
    CONCAT('Q', DATEPART(quarter, d), '-', DATEPART(year, d))
FROM Dates d
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_date x WHERE x.date_id = CONVERT(char(8), d, 112))
OPTION (MAXRECURSION 0);

PRINT 'dim_date seeded for window.';

/* ----------------------------------------------------------------------------
2) Reference dims (idempotent seeds)
---------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dwh.dim_grade)
BEGIN
    INSERT INTO dwh.dim_grade (grade_id, grade_name, grade_type, paying, employed, student, [status], grade_display, reporting_category, membership_category, parent_grade_name, performance_grade)
    VALUES
    (NEWID(), 'Applicant', 'Non Chartered', '1','1','0','Current','Applicant','Applicant','Applicant','Applicant','Other'),
    (NEWID(), 'Member', 'Chartered', '1','1','0','Current','Member','Member','Chartered','Member','Other'),
    (NEWID(), 'Fellow', 'Chartered', '1','1','0','Current','Fellow','Fellow','Chartered','Fellow','Other'),
    (NEWID(), 'Retired Member', 'Chartered', '1','0','0','Current','Retired Member','Retired Member','Chartered','Member','Non-Targeted Grades'),
    (NEWID(), 'TechCIOB', 'Non Chartered', '1','1','0','Current','Technical','Technical','Technical','Technical','Other'),
    (NEWID(), 'Educator Pathway', 'Non Chartered', '1','1','0','Current','Applicant','Applicant','Applicant','Applicant','Other');
    PRINT 'dim_grade seeded.';
END;

IF NOT EXISTS (SELECT 1 FROM dwh.dim_hub)
BEGIN
    INSERT INTO dwh.dim_hub (local_hub_id, local_hub, area_hub_id, area_hub_name, regional_group_id, regional_group, regional_hub_id, regional_hub, super_region_id, super_region, country_id, country_name, economic_region_id, economic_region, europe_international, [status], [state], region_code)
    VALUES
    (NEWID(),'London',2,'North',NEWID(),'UK North',NEWID(),'Europe',NEWID(),'Europe',NEWID(),'United Kingdom',NEWID(),'United Kingdom','Europe','Active','Active','EUR'),
    (NEWID(),'New York',91,'Americas',NEWID(),'New York',NEWID(),'Americas',NEWID(),'Americas',NEWID(),'United States',NEWID(),'Americas','International','Active','Active','AMS'),
    (NEWID(),'Toronto',91,'Americas',NEWID(),'Toronto',NEWID(),'Americas',NEWID(),'Americas',NEWID(),'Canada',NEWID(),'Americas','International','Active','Active','AMS'),
    (NEWID(),'Beijing',92,'China',NEWID(),'Beijing',NEWID(),'Asia',NEWID(),'Asia',NEWID(),'China',NEWID(),'China','International','Active','Active','ASIA'),
    (NEWID(),'Shanghai',92,'China',NEWID(),'Shanghai',NEWID(),'Asia',NEWID(),'Asia',NEWID(),'China',NEWID(),'China','International','Active','Active','ASIA'),
    (NEWID(),'Kuala Lumpur',92,'Malaysia',NEWID(),'Kuala Lumpur',NEWID(),'Asia',NEWID(),'Asia',NEWID(),'Malaysia',NEWID(),'Malaysia','International','Active','Active','ASIA');
    PRINT 'dim_hub seeded.';
END;

IF NOT EXISTS (SELECT 1 FROM dwh.dim_product)
BEGIN
    INSERT INTO dwh.dim_product (product_id, product_name, product_number, product_type, product_category, vat_rate, [state], amount, amount_base, purchase_type, sold_externally, academy_product_id, grade)
    VALUES
    (NEWID(),'Applicants','MEM-1001','Sales Inventory',NULL,'8-0% (STD)','Active',NULL,NULL,NULL,NULL,NULL,NULL),
    (NEWID(),'Members','MEM-1011','Sales Inventory',NULL,'E-0% (XPT)','Active',NULL,NULL,NULL,NULL,NULL,NULL),
    (NEWID(),'Fellows','MEM-1009','Sales Inventory',NULL,'8-0% (STD)','Active',NULL,NULL,NULL,NULL,NULL,NULL),
    (NEWID(),'TechCIOB','MEM-1010','Sales Inventory',NULL,'8-0% (STD)','Active',NULL,NULL,NULL,NULL,NULL,NULL),
    (NEWID(),'Retired Member','MEM-1012','Sales Inventory',NULL,'2-0% (OOS)','Active',NULL,NULL,NULL,NULL,NULL,NULL),
    (NEWID(),'Educator Pathway','MEM-1007','Sales Inventory',NULL,'8-0% (STD)','Active',NULL,NULL,NULL,NULL,NULL,NULL);
    PRINT 'dim_product seeded.';
END;

IF NOT EXISTS (SELECT 1 FROM dwh.dim_organisation)
BEGIN
    INSERT INTO dwh.dim_organisation
    (
      organisation_id, organisation_name, cbc_type, is_study_centre, is_exam_centre,
      address_city, address_country, address_postalcode,
      currency, local_hub, regional_hub, [state], [status], owner
    )
    VALUES
    (NEWID(), 'TAYLOR WHIMPY', 'None', 'FALSE', 'FALSE',
     'LONDON', 'United Kingdom', 'TW3 4GA',
     'British Pound', 'N&E Yorkshire & Humber', 'Europe (Regional Hub)', 'Inactive', 'Inactive', '# BLC App Services'),
    (NEWID(), 'BARRATS', 'None', 'FALSE', 'FALSE',
     'BIRMINGHAM', 'United Kingdom', 'TW3 HDS',
     'British Pound', 'Doha', 'Middle East & North Africa (Regional Hub)', 'Inactive', 'Inactive', '# BLC App Services');
    PRINT 'dim_organisation seeded.';
END;

/* ----------------------------------------------------------------------------
3) Parameter tables (seasonality, mixes)
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#MonthWeight') IS NOT NULL DROP TABLE #MonthWeight;
CREATE TABLE #MonthWeight (month_no int primary key, weight float not null);
INSERT INTO #MonthWeight(month_no, weight) VALUES
(1, 1.30),(2,1.15),(3,1.10),(4,1.00),(5,0.95),(6,0.90),
(7,0.85),(8,0.90),(9,1.20),(10,1.10),(11,1.00),(12,0.60);

IF OBJECT_ID('tempdb..#DowWeight') IS NOT NULL DROP TABLE #DowWeight;
CREATE TABLE #DowWeight (weekday_no int primary key, weight float not null);
INSERT INTO #DowWeight(weekday_no, weight) VALUES
(1, 1.00),(2,1.05),(3,1.05),(4,1.05),(5,1.00),(6,0.60),(7,0.50);

IF OBJECT_ID('tempdb..#GradeWeight') IS NOT NULL DROP TABLE #GradeWeight;
CREATE TABLE #GradeWeight (grade_id int not null, weight float not null);
INSERT INTO #GradeWeight(grade_id, weight)
SELECT id, w FROM (
    SELECT g.id,
           CASE g.grade_name
                WHEN 'Applicant'        THEN 0.40
                WHEN 'Member'           THEN 0.35
                WHEN 'TechCIOB'         THEN 0.10
                WHEN 'Fellow'           THEN 0.05
                WHEN 'Retired Member'   THEN 0.05
                WHEN 'Educator Pathway' THEN 0.05
                ELSE 0.01
           END AS w
    FROM dwh.dim_grade g
) x;

IF OBJECT_ID('tempdb..#HubWeight') IS NOT NULL DROP TABLE #HubWeight;
CREATE TABLE #HubWeight (hub_id int not null, weight float not null);
INSERT INTO #HubWeight(hub_id, weight)
SELECT id, w FROM (
    SELECT h.id,
           CASE h.country_name
                WHEN 'United Kingdom' THEN 0.45
                WHEN 'United States'  THEN 0.20
                WHEN 'Canada'         THEN 0.10
                WHEN 'China'          THEN 0.15
                WHEN 'Malaysia'       THEN 0.10
                ELSE 0.05
           END AS w
    FROM dwh.dim_hub h
) x;

IF OBJECT_ID('tempdb..#ProductPrice') IS NOT NULL DROP TABLE #ProductPrice;
CREATE TABLE #ProductPrice (product_id int not null, base_price money not null, grade_name varchar(100));
INSERT INTO #ProductPrice(product_id, base_price, grade_name)
SELECT p.id,
       CASE p.product_name
            WHEN 'Applicants'       THEN 120
            WHEN 'Members'          THEN 335
            WHEN 'Fellows'          THEN 450
            WHEN 'TechCIOB'         THEN 200
            WHEN 'Retired Member'   THEN 198
            WHEN 'Educator Pathway' THEN 250
            ELSE 150
       END,
       CASE p.product_name
            WHEN 'Applicants'       THEN 'Applicant'
            WHEN 'Members'          THEN 'Member'
            WHEN 'Fellows'          THEN 'Fellow'
            WHEN 'TechCIOB'        THEN 'TechCIOB'
            WHEN 'Retired Member'   THEN 'Retired Member'
            WHEN 'Educator Pathway' THEN 'Educator Pathway'
            ELSE 'Applicant'
       END
FROM dwh.dim_product p;

IF OBJECT_ID('tempdb..#PayMix') IS NOT NULL DROP TABLE #PayMix;
CREATE TABLE #PayMix(method varchar(50) primary key, pct float not null);
INSERT INTO #PayMix(method, pct) VALUES
('Online - Portal', 0.60),
('Direct Debit (Monthly)', 0.35),
('Manual Bank Transfer', 0.05);

/* ----------------------------------------------------------------------------
4) Daily plan
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#DayPlan') IS NOT NULL DROP TABLE #DayPlan;
CREATE TABLE #DayPlan(date_id int not null, d date not null, target_count int not null);

INSERT INTO #DayPlan(date_id, d, target_count)
SELECT
    CAST(dd.date_id AS int),
    CAST(dd.[date] AS date),
    CAST(ROUND(
        ((CASE WHEN dw.weekday_no IN (6,7) THEN @SeedBaseWeekend ELSE @SeedBaseWeekday END) * mw.weight * dw.weight)
        * (0.8 + ((ABS(CHECKSUM(NEWID())) % 400000) / 1000000.0)), 0) AS int)
FROM dwh.dim_date dd
JOIN #MonthWeight mw ON mw.month_no = DATEPART(month, dd.[date])
JOIN #DowWeight dw   ON dw.weekday_no = ((DATEPART(WEEKDAY, dd.[date]) + @@DATEFIRST + 5) % 7) + 1
WHERE dd.[date] BETWEEN @StartDate AND @EndDate;

/* ----------------------------------------------------------------------------
5) New members per day
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#NewMembers') IS NOT NULL DROP TABLE #NewMembers;
CREATE TABLE #NewMembers (
    seq_id          bigint IDENTITY(1,1) PRIMARY KEY,
    start_date      date not null,
    start_date_fk   int  not null,
    grade_fk        int  not null,
    hub_fk          int  not null,
    product_fk      int  not null,
    price           money not null,
    pay_method      varchar(50) not null,
    contact_id      uniqueidentifier not null,
    first_name      nvarchar(100) not null,
    last_name       nvarchar(100) not null,
    gender          varchar(10)   not null,
    age             int           not null,
    date_of_birth   date          not null,
    organisation_fk int           null
);

;WITH E AS (
    SELECT dp.d, dp.date_id, dp.target_count
    FROM #DayPlan dp
), Expanded AS (
    SELECT e.d, e.date_id, x.k
    FROM E e
    CROSS APPLY (SELECT TOP (CASE WHEN e.target_count < 0 THEN 0 ELSE e.target_count END)
                 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS k
                 FROM sys.all_objects) x
)
INSERT INTO #NewMembers
(
    start_date, start_date_fk, grade_fk, hub_fk, product_fk, price, pay_method,
    contact_id, first_name, last_name, gender, age, date_of_birth, organisation_fk
)
SELECT
    ex.d,
    ex.date_id,
    gw.grade_id,
    hw.hub_id,
    pp.product_id,
    pp.base_price,
    pm.method,
    NEWID(),
    fn.first_name,
    ln.last_name,
    CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 50 THEN 'Male' ELSE 'Female' END,
    ag.age,
    DATEADD(year, -ag.age, ex.d),
    CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 25
         THEN (SELECT TOP 1 id FROM dwh.dim_organisation ORDER BY NEWID())
         ELSE NULL END
FROM Expanded ex
CROSS APPLY (
    SELECT TOP 1 g.grade_id
    FROM (SELECT g.grade_id, SUM(g.weight) OVER (ORDER BY g.grade_id) / SUM(g.weight) OVER () AS cum
          FROM #GradeWeight g) g
    WHERE g.cum >= ((ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0)
    ORDER BY g.cum
) gw
CROSS APPLY (
    SELECT TOP 1 h.hub_id
    FROM (SELECT h.hub_id, SUM(h.weight) OVER (ORDER BY h.hub_id) / SUM(h.weight) OVER () AS cum
          FROM #HubWeight h) h
    WHERE h.cum >= ((ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0)
    ORDER BY h.cum
) hw
CROSS APPLY (
    SELECT TOP 1 p.product_id, p.base_price
    FROM #ProductPrice p
    JOIN dwh.dim_grade g ON g.grade_name = p.grade_name AND g.id = gw.grade_id
    ORDER BY NEWID()
) pp
CROSS APPLY (
    SELECT TOP 1 method
    FROM (SELECT m.method, SUM(m.pct) OVER (ORDER BY m.method) / SUM(m.pct) OVER () AS cum FROM #PayMix m) m
    WHERE m.cum >= ((ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0)
    ORDER BY m.cum
) pm
CROSS APPLY (SELECT TOP 1 v AS first_name FROM (VALUES
    (N'Alex'),(N'Sam'),(N'Jordan'),(N'Priya'),(N'Chen'),(N'Maria'),
    (N'Fatima'),(N'Liam'),(N'Noah'),(N'Emma'),(N'Ava'),(N'Olivia')
) n(v) ORDER BY NEWID()) fn
CROSS APPLY (SELECT TOP 1 v AS last_name FROM (VALUES
    (N'Smith'),(N'Johnson'),(N'Williams'),(N'Brown'),(N'Jones'),(N'Garcia'),
    (N'Miller'),(N'Davis'),(N'Wilson'),(N'Taylor'),(N'Anderson'),(N'Thompson')
) n(v) ORDER BY NEWID()) ln
CROSS APPLY (SELECT rv = (ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0) rnd
CROSS APPLY (SELECT age = CASE
    WHEN rnd.rv < 0.05 THEN 22 + (ABS(CHECKSUM(NEWID())) % 3)      -- 22-24
    WHEN rnd.rv < 0.25 THEN 25 + (ABS(CHECKSUM(NEWID())) % 10)     -- 25-34
    WHEN rnd.rv < 0.55 THEN 35 + (ABS(CHECKSUM(NEWID())) % 10)     -- 35-44
    WHEN rnd.rv < 0.80 THEN 45 + (ABS(CHECKSUM(NEWID())) % 10)     -- 45-54
    WHEN rnd.rv < 0.95 THEN 55 + (ABS(CHECKSUM(NEWID())) % 10)     -- 55-64
    ELSE 65 + (ABS(CHECKSUM(NEWID())) % 15)                         -- 65-79
END) ag;

DECLARE @planned int; SELECT @planned = COUNT(*) FROM #NewMembers;
PRINT CONCAT('Planned admissions rows: ', @planned);

/* ----------------------------------------------------------------------------
6) dim_member + mapping
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#MemberMap') IS NOT NULL DROP TABLE #MemberMap;
CREATE TABLE #MemberMap (
    seq_id        bigint primary key,
    member_id     int    not null,
    membership_no varchar(20) not null
);

;WITH S AS (
    SELECT nm.*, ROW_NUMBER() OVER (ORDER BY nm.seq_id) AS rn
    FROM #NewMembers nm
)
MERGE dwh.dim_member AS T
USING (SELECT S.seq_id, S.contact_id, S.first_name, S.last_name, S.gender, S.age, S.date_of_birth, S.rn FROM S) AS src
ON 1 = 2
WHEN NOT MATCHED THEN
    INSERT (
        contact_id, title, first_name, middle_name, last_name, full_name, certificate_name, salutation,
        job_title, gender, registered_disables_tatus, age, age_group, generation, membership_number,
        membership_grade, membership_status, parent_customer_id, date_of_birth, email_preferred, email_home, email_work,
        phone_preferred, phone_mobile, phone_home, phone_business,
        status, portal_user_id, academy_id, academy_registration_date, is_ciob_member, modified_on, account_id
    )
    VALUES (
        src.contact_id,
        CASE WHEN (ABS(CHECKSUM(NEWID())) % 4)=0 THEN 'Mr' WHEN (ABS(CHECKSUM(NEWID())) % 4)=1 THEN 'Ms' ELSE 'Mrs' END,
        src.first_name, NULL, src.last_name,
        CONCAT(src.first_name, ' ', src.last_name),
        CONCAT(src.first_name, ' ', src.last_name),
        CONCAT('Mr/Ms ', src.last_name),
        NULL,
        src.gender,
        CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 3 THEN 'TRUE' ELSE 'FALSE' END,
        src.age,
        CASE WHEN src.age BETWEEN 25 AND 34 THEN '25 to 34'
             WHEN src.age BETWEEN 35 AND 44 THEN '35 to 44'
             WHEN src.age BETWEEN 45 AND 54 THEN '45 to 54'
             WHEN src.age BETWEEN 55 AND 64 THEN '55 to 64'
             WHEN src.age >= 65 THEN '65 and over' ELSE '18 to 24' END,
        CASE WHEN src.age >= 56 THEN 'baby boomers'
             WHEN src.age BETWEEN 41 AND 55 THEN 'gen x'
             WHEN src.age BETWEEN 25 AND 40 THEN 'gen y'
             ELSE 'gen z' END,
        RIGHT(CONCAT('0000000', CAST(3000000 + src.rn AS varchar(12))), 7),
        NULL, 'Active', NULL, src.date_of_birth,
        LOWER(CONCAT(src.first_name, '.', src.last_name, '@example.org')),
        NULL, NULL, NULL, NULL, NULL, NULL, 'Active', NULL, NULL, NULL, NULL, SYSUTCDATETIME(), NULL
    )
OUTPUT src.seq_id, INSERTED.id, INSERTED.membership_number
INTO #MemberMap(seq_id, member_id, membership_no);

PRINT CONCAT('dim_member inserted: ', @@ROWCOUNT);

/* ----------------------------------------------------------------------------
7) Admissions (apply membership rules)
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Admissions') IS NOT NULL DROP TABLE #Admissions;
CREATE TABLE #Admissions (
    seq_id          bigint primary key,
    member_fk       int not null,
    organisation_fk int null,
    grade_fk        int not null,
    hub_fk          int not null,
    product_fk      int not null,
    start_date      date not null,
    start_date_fk   int not null,
    active_date_fk  int not null,
    expiry_date     date not null,
    expiry_date_fk  int not null,
    end_date_fk     int not null,
    price           money not null,
    pay_method      varchar(50) not null,
    invoice_id      uniqueidentifier NULL  -- FIX-005
);

INSERT INTO #Admissions (seq_id, member_fk, organisation_fk, grade_fk, hub_fk, product_fk, start_date, start_date_fk, active_date_fk, expiry_date, expiry_date_fk, end_date_fk, price, pay_method)
SELECT
    nm.seq_id,
    mm.member_id,
    nm.organisation_fk,
    nm.grade_fk,
    nm.hub_fk,
    nm.product_fk,
    nm.start_date,
    nm.start_date_fk,
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(nm.start_date), MONTH(nm.start_date), 1), 112) AS int) AS active_date_fk,   -- Rule: active = 1st of month
    CASE WHEN nm.organisation_fk IS NULL
         THEN DATEFROMPARTS(YEAR(nm.start_date), 12, 31)                                 -- Individuals: end 31-Dec same year
         ELSE DATEADD(day, -1, DATEADD(year, 1, nm.start_date))                           -- Companies: +1 year -1 day
    END AS expiry_date,
    CAST(CONVERT(char(8),
        CASE WHEN nm.organisation_fk IS NULL
             THEN DATEFROMPARTS(YEAR(nm.start_date), 12, 31)
             ELSE DATEADD(day, -1, DATEADD(year, 1, nm.start_date))
        END, 112) AS int) AS expiry_date_fk,
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(nm.start_date), 12, 31), 112) AS int) AS end_date_fk,  -- Rule: end_date_fk always 31-Dec
    nm.price,
    nm.pay_method
FROM #NewMembers nm
JOIN #MemberMap mm ON mm.seq_id = nm.seq_id;

-- Insert admissions into fact_membership, capture membership_id
IF OBJECT_ID('tempdb..#StatusPick') IS NOT NULL DROP TABLE #StatusPick;
CREATE TABLE #StatusPick(seq_id bigint primary key, status_label varchar(20), is_attrition bit);

INSERT INTO #StatusPick(seq_id, status_label, is_attrition)
SELECT z.seq_id,   -- FIX-004
       CASE WHEN r < 0.02 THEN 'Deceased' WHEN r < 0.07 THEN 'Resigned' ELSE 'Active' END,
       CASE WHEN r < 0.07 THEN 1 ELSE 0 END
FROM (
    SELECT a.seq_id, (ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0 AS r
    FROM #Admissions a
) z;

IF OBJECT_ID('tempdb..#PricingPick') IS NOT NULL DROP TABLE #PricingPick;
CREATE TABLE #PricingPick(seq_id bigint primary key, sp varchar(20));
INSERT INTO #PricingPick(seq_id, sp)
SELECT p.seq_id,   -- FIX-004
       CASE WHEN r < 0.05 THEN 'concession'
            WHEN r < 0.08 THEN 'maternity'
            WHEN r < 0.12 THEN 'academic'
            ELSE 'standard' END
FROM (SELECT a.seq_id, (ABS(CHECKSUM(NEWID())) % 1000000) / 1000000.0 AS r FROM #Admissions a) p;

IF OBJECT_ID('tempdb..#FMInserted') IS NOT NULL DROP TABLE #FMInserted;
CREATE TABLE #FMInserted(member_fk int PRIMARY KEY, membership_id uniqueidentifier, start_date_fk int, organisation_fk int, individual_flag bit, join_year int, expiry_date_fk int);

INSERT INTO dwh.fact_membership
(
    member_fk, organisation_fk, product_fk, grade_fk, prev_grade_fk, hub_fk, currency_fk,
    owner_fk, start_date_fk, expiry_date_fk, admit_to_membership_date_fk, cbc_document_date_fk,
    membership_id, membership_number, membership_number_grade_concat, membership_name,
    total_value, total_value_base, special_pricing, invoice_id, direct_debit_mandate,
    [state], [status], membership_status_original, membership_type_original,
    previous_membership_id, age_at_membership_start, age_group_at_membership_start,
    created_date, created_date_fk, modified_date, modified_date_fk,
    pending_date_fk, active_date_fk, end_date_fk, deleted_date_fk,
    membership_status_derived, membership_type_derived,
    is_admission, is_upgrade, is_reinstatement, is_attrition,
    no_of_company_professional_staff, Annual_Revenue_Band, contact_id, special_pricing_reason
)
OUTPUT INSERTED.member_fk, INSERTED.membership_id,
       INSERTED.start_date_fk, INSERTED.organisation_fk,
       CASE WHEN INSERTED.organisation_fk IS NULL THEN 1 ELSE 0 END,
       (INSERTED.start_date_fk / 10000),
       INSERTED.expiry_date_fk
INTO #FMInserted(member_fk, membership_id, start_date_fk, organisation_fk, individual_flag, join_year, expiry_date_fk)
SELECT
    a.member_fk, a.organisation_fk, a.product_fk, a.grade_fk, NULL, a.hub_fk, @BaseCurrencyFk,
    NULL, a.start_date_fk, a.expiry_date_fk, a.start_date_fk, NULL,
    NEWID(),   -- membership_id (captured above)
    m.membership_number,
    CONCAT(m.membership_number, '+', g.id),
    CONCAT(m.first_name, ' ', m.last_name),
    CAST(a.price AS decimal(38,4)),
    CAST(a.price AS decimal(38,4)),
    pr.sp,     -- special_pricing
    NULL, NULL,
    'Active', 'Join',
    sp.status_label, 'Join',
    NULL,
    DATEDIFF(year, m.date_of_birth, a.start_date),
    CASE
        WHEN DATEDIFF(year, m.date_of_birth, a.start_date) BETWEEN 25 AND 34 THEN '25 to 34'
        WHEN DATEDIFF(year, m.date_of_birth, a.start_date) BETWEEN 35 AND 44 THEN '35 to 44'
        WHEN DATEDIFF(year, m.date_of_birth, a.start_date) BETWEEN 45 AND 54 THEN '45 to 54'
        WHEN DATEDIFF(year, m.date_of_birth, a.start_date) BETWEEN 55 AND 64 THEN '55 to 64'
        WHEN DATEDIFF(year, m.date_of_birth, a.start_date) >= 65 THEN '65 and over'
        ELSE '18 to 24'
    END,
    SYSUTCDATETIME(), a.start_date_fk, SYSUTCDATETIME(), a.start_date_fk,
    NULL,
    a.active_date_fk,                                     -- Rule: active_date_fk = 1st of month
    a.end_date_fk,                                        -- Rule: end_date_fk = 31-Dec
    NULL,
    'Active', 'Join',
    1, 0, 0, sp.is_attrition,                             -- flags: is_admission=1; is_attrition if resigned/deceased
    NULL, NULL, CONVERT(varchar(38), m.contact_id),
    pr.sp                                                -- special_pricing_reason (same as special_pricing label)
FROM #Admissions a
JOIN dwh.dim_member m ON m.id = a.member_fk
JOIN dwh.dim_grade  g ON g.id = a.grade_fk
JOIN #StatusPick sp ON sp.seq_id = a.seq_id
JOIN #PricingPick pr ON pr.seq_id = a.seq_id;

PRINT CONCAT('fact_membership admissions inserted: ', @@ROWCOUNT);

/* ----------------------------------------------------------------------------
8) Admission invoices & payments
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Inv') IS NOT NULL DROP TABLE #Inv;
CREATE TABLE #Inv (seq_id bigint primary key, invoice_id uniqueidentifier not null);

MERGE dwh.fact_invoice AS T
USING (
    SELECT a.seq_id, a.member_fk, a.product_fk, a.start_date_fk, a.start_date, a.hub_fk, a.organisation_fk, a.price
    FROM #Admissions a
) AS src
ON 1=2
WHEN NOT MATCHED THEN
    INSERT
    (
        member_fk, currency_fk, product_fk, invoice_date_fk, due_date_fk, billing_year_fk,
        organisation_fk, invoice_id, invoice_name, invoice_number, salesorderid, line_number,
        invoice_amount, outstanding_amount, quantity, unit_price, line_amount, discount_amount, vat_amount, extended_amount,
        [state], [status], invoice_type, invoice_detail_id, created_on_date_fk, modified_on_date_fk,
        is_renewal, is_floating_renewal, credit_allocated_invoice_name, bluemem_membershipgroupid
    )
    VALUES
    (
        src.member_fk, @BaseCurrencyFk, src.product_fk,
        src.start_date_fk,
        CAST(CONVERT(char(8), DATEADD(day, 30, src.start_date), 112) AS int),
        DATEPART(year, src.start_date),
        src.organisation_fk,
        NEWID(),
        CONCAT('INV-', RIGHT(CONVERT(varchar(10), src.start_date_fk), 6), '-', src.member_fk, '-1'),
        CONCAT('INV-', RIGHT(CONVERT(varchar(10), src.start_date_fk), 6), '-', src.member_fk),
        NULL, 1,
        CAST(src.price AS decimal(38,4)),
        CAST(src.price AS decimal(38,4)),
        1, CAST(src.price AS decimal(38,4)), CAST(src.price AS decimal(38,4)),
        CAST(0 AS decimal(38,2)),
        CAST(0 AS decimal(38,4)),
        CAST(src.price AS decimal(38,4)),
        'Active','Active','Invoice', NEWID(),
        src.start_date_fk, src.start_date_fk,
        0, 0, NULL, NULL
    )
OUTPUT src.seq_id, INSERTED.invoice_id
INTO #Inv(seq_id, invoice_id);

UPDATE a SET a.invoice_id = i.invoice_id
FROM #Admissions a
JOIN #Inv i ON i.seq_id = a.seq_id;

-- One-off payments
INSERT INTO dwh.fact_payment
(
    contact_fk, orgnisation_fk, currency_fk, hub_fk, member_fk, payment_date_fk, payment_created_date_fk,
    invoice_date_fk, payment_billing_year_fk, invoice_billing_year_fk, payment_id, payment_name,
    payment_amount, payment_amount_base, exchange_rate, payment_type, payment_state, payment_status,
    bacs_ref, payment_ref_no, provider_tx_auth_code, invoice_id, invoice_name, invoice_status,
    bluefun_recurringdonationid, is_renewal, is_floating_renewal, is_late_renewal
)
SELECT
    a.member_fk, a.organisation_fk, @BaseCurrencyFk, a.hub_fk, a.member_fk,
    CAST(CONVERT(char(8), DATEADD(day, CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 70 THEN 0 ELSE (ABS(CHECKSUM(NEWID())) % 10) END, a.start_date), 112) AS int),
    a.start_date_fk,
    a.start_date_fk,
    DATEPART(year, a.start_date),
    DATEPART(year, a.start_date),
    NEWID(), CONCAT('PAY-', RIGHT(CONVERT(varchar(10), a.start_date_fk), 6), '-', a.member_fk),
    CAST(a.price AS decimal(38,4)), CAST(a.price AS decimal(38,4)), CAST(1.0 AS decimal(38,10)),
    'Online - Portal',
    'Active', CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 95 THEN 'Paid' ELSE 'Failed' END,
    NULL, NULL, NULL,
    a.invoice_id, NULL, 'Active',
    NULL, 0, 0, 0
FROM #Admissions a
WHERE a.pay_method <> 'Direct Debit (Monthly)';

-- Direct debit (12)
;WITH Months AS (
    SELECT 1 AS m UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
INSERT INTO dwh.fact_payment
(
    contact_fk, orgnisation_fk, currency_fk, hub_fk, member_fk, payment_date_fk, payment_created_date_fk,
    invoice_date_fk, payment_billing_year_fk, invoice_billing_year_fk, payment_id, payment_name,
    payment_amount, payment_amount_base, exchange_rate, payment_type, payment_state, payment_status,
    bacs_ref, payment_ref_no, provider_tx_auth_code, invoice_id, invoice_name, invoice_status,
    bluefun_recurringdonationid, is_renewal, is_floating_renewal, is_late_renewal
)
SELECT
    a.member_fk, a.organisation_fk, @BaseCurrencyFk, a.hub_fk, a.member_fk,
    CAST(CONVERT(char(8),
        DATEADD(day,
            CASE WHEN DATEPART(WEEKDAY, DATEADD(month, m.m-1, a.start_date)) IN (1,7) THEN 2 ELSE 0 END +
            (ABS(CHECKSUM(NEWID())) % 2),
            DATEADD(month, m.m-1, a.start_date)
        ), 112) AS int),
    a.start_date_fk,
    a.start_date_fk,
    DATEPART(year, a.start_date),
    DATEPART(year, a.start_date),
    NEWID(), CONCAT('PAY-DD-', RIGHT(CONVERT(varchar(10), a.start_date_fk), 6), '-', a.member_fk, '-', m.m),
    CAST(a.price/12.0 AS decimal(38,4)), CAST(a.price/12.0 AS decimal(38,4)), CAST(1.0 AS decimal(38,10)),
    'Direct Debit (Monthly)',
    'Active', 'Paid',
    NULL, NULL, NULL,
    a.invoice_id, NULL, 'Active',
    NULL, 0, 0, 0
FROM #Admissions a
JOIN Months m ON 1=1
WHERE a.pay_method = 'Direct Debit (Monthly)';

;WITH Paid AS (
    SELECT p.invoice_id, SUM(CASE WHEN p.payment_status='Paid' THEN p.payment_amount ELSE 0 END) AS paid
    FROM dwh.fact_payment p
    GROUP BY p.invoice_id
)
UPDATE inv
SET outstanding_amount = CAST(inv.invoice_amount - ISNULL(p.paid,0) AS decimal(38,4))
FROM dwh.fact_invoice inv
LEFT JOIN Paid p ON p.invoice_id = inv.invoice_id;

PRINT 'Admission invoices and payments generated.';

/* ----------------------------------------------------------------------------
9) Upgrades (retain same membership_id; prev_grade_fk set; is_upgrade=1)
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Upgrades') IS NOT NULL DROP TABLE #Upgrades;
CREATE TABLE #Upgrades (
    member_fk int not null PRIMARY KEY,
    upgrade_date date not null,
    upgrade_start_fk int not null,
    active_date_fk int not null,
    end_date_fk int not null,
    new_grade_fk int not null,
    prev_grade_fk int not null,
    expiry_date_fk int not null,
    membership_id uniqueidentifier not null,
    hub_fk int not null,
    product_fk int not null,
    organisation_fk int null
);

;WITH Elig AS (
    SELECT a.*, g.grade_name,
           CASE g.grade_name
                WHEN 'Applicant' THEN 'Member'
                WHEN 'Member' THEN 'Fellow'
                WHEN 'TechCIOB' THEN 'Member'
                WHEN 'Educator Pathway' THEN 'Member'
                ELSE NULL END AS next_grade_name
    FROM #Admissions a
    JOIN dwh.dim_grade g ON g.id = a.grade_fk
    WHERE (ABS(CHECKSUM(NEWID())) % 100) < 10  -- 10% upgrades
      AND a.expiry_date >= a.start_date
), NextG AS (
    SELECT e.*, g2.id AS new_grade_fk
    FROM Elig e
    LEFT JOIN dwh.dim_grade g2 ON g2.grade_name = e.next_grade_name
    WHERE g2.id IS NOT NULL AND e.next_grade_name IS NOT NULL
), Dates AS (
    SELECT n.*,
           CASE
              WHEN DATEADD(day, 15, n.start_date) < DATEADD(day, -10, n.expiry_date)
              THEN DATEADD(day, 15 + (ABS(CHECKSUM(NEWID())) % NULLIF(DATEDIFF(day, DATEADD(day,15,n.start_date), DATEADD(day,-10,n.expiry_date)),0)),
                           n.start_date)
              ELSE DATEADD(day, 15, n.start_date)
           END AS upgrade_date_calc
    FROM NextG n
)
INSERT INTO #Upgrades(member_fk, upgrade_date, upgrade_start_fk, active_date_fk, end_date_fk, new_grade_fk, prev_grade_fk, expiry_date_fk, membership_id, hub_fk, product_fk, organisation_fk)
SELECT
    d.member_fk,
    d.upgrade_date_calc,
    CAST(CONVERT(char(8), d.upgrade_date_calc, 112) AS int) AS upgrade_start_fk,
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(d.upgrade_date_calc), MONTH(d.upgrade_date_calc), 1), 112) AS int) AS active_date_fk,
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(d.start_date), 12, 31), 112) AS int) AS end_date_fk,
    d.new_grade_fk,
    d.grade_fk AS prev_grade_fk,
    d.expiry_date_fk,
    f.membership_id,
    d.hub_fk,
    d.product_fk,
    d.organisation_fk
FROM Dates d
JOIN #FMInserted f ON f.member_fk = d.member_fk;

INSERT INTO dwh.fact_membership
(
    member_fk, organisation_fk, product_fk, grade_fk, prev_grade_fk, hub_fk, currency_fk,
    owner_fk, start_date_fk, expiry_date_fk, admit_to_membership_date_fk, cbc_document_date_fk,
    membership_id, membership_number, membership_number_grade_concat, membership_name,
    total_value, total_value_base, special_pricing, invoice_id, direct_debit_mandate,
    [state], [status], membership_status_original, membership_type_original,
    previous_membership_id, age_at_membership_start, age_group_at_membership_start,
    created_date, created_date_fk, modified_date, modified_date_fk,
    pending_date_fk, active_date_fk, end_date_fk, deleted_date_fk,
    membership_status_derived, membership_type_derived,
    is_admission, is_upgrade, is_reinstatement, is_attrition,
    no_of_company_professional_staff, Annual_Revenue_Band, contact_id, special_pricing_reason
)
SELECT
    u.member_fk, u.organisation_fk, u.product_fk, u.new_grade_fk, u.prev_grade_fk, u.hub_fk, @BaseCurrencyFk,
    NULL, u.upgrade_start_fk, u.expiry_date_fk, u.upgrade_start_fk, NULL,
    u.membership_id,
    m.membership_number,
    CONCAT(m.membership_number, '+', u.new_grade_fk),
    CONCAT(m.first_name, ' ', m.last_name),
    CAST(0 AS decimal(38,4)),
    CAST(0 AS decimal(38,4)),
    'standard',
    NULL, NULL,
    'Active', 'Upgrade',
    'Active', 'Upgrade',
    NULL,
    DATEDIFF(year, m.date_of_birth, dd.[date]),
    CASE
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 25 AND 34 THEN '25 to 34'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 35 AND 44 THEN '35 to 44'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 45 AND 54 THEN '45 to 54'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 55 AND 64 THEN '55 to 64'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) >= 65 THEN '65 and over'
        ELSE '18 to 24'
    END,
    SYSUTCDATETIME(), u.upgrade_start_fk, SYSUTCDATETIME(), u.upgrade_start_fk,
    NULL, u.active_date_fk, u.end_date_fk, NULL,
    'Active', 'Upgrade',
    0, 1, 0, 0,
    NULL, NULL, CONVERT(varchar(38), m.contact_id), 'standard'
FROM #Upgrades u
JOIN dwh.dim_member m ON m.id = u.member_fk
JOIN dwh.dim_date dd ON dd.date_id = u.upgrade_start_fk;

PRINT CONCAT('Upgrades inserted: ', @@ROWCOUNT);

/* ----------------------------------------------------------------------------
10) Rejoins
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Resigned') IS NOT NULL DROP TABLE #Resigned;
CREATE TABLE #Resigned(member_fk int PRIMARY KEY, start_date date, start_date_fk int, end_year int, membership_id uniqueidentifier, hub_fk int, grade_fk int, product_fk int, organisation_fk int, expiry_date_fk int);

INSERT INTO #Resigned(member_fk, start_date, start_date_fk, end_year, membership_id, hub_fk, grade_fk, product_fk, organisation_fk, expiry_date_fk)
SELECT TOP (CAST((SELECT COUNT(*)*0.05 FROM #FMInserted) AS int))
    f.member_fk, dd.date, f.start_date_fk, DATEPART(year, dd2.date), f.membership_id,
    a.hub_fk, a.grade_fk, a.product_fk, a.organisation_fk, f.expiry_date_fk
FROM #FMInserted f
JOIN dwh.fact_membership fm ON fm.member_fk = f.member_fk AND fm.membership_type_original='Join'
JOIN dwh.dim_date dd  ON dd.date_id = f.start_date_fk
JOIN #Admissions a ON a.member_fk = f.member_fk
JOIN dwh.dim_date dd2 ON dd2.date_id = a.end_date_fk
JOIN #StatusPick sp ON sp.seq_id = a.seq_id AND sp.status_label='Resigned'
ORDER BY NEWID();

IF OBJECT_ID('tempdb..#Rejoins') IS NOT NULL DROP TABLE #Rejoins;
CREATE TABLE #Rejoins (
    member_fk int PRIMARY KEY,
    rejoin_date date not null,
    rejoin_start_fk int not null,
    active_date_fk int not null,
    end_date_fk int not null,
    grade_fk int not null,
    expiry_date_fk int not null,
    membership_id uniqueidentifier not null,
    hub_fk int not null,
    product_fk int not null,
    organisation_fk int null
);

INSERT INTO #Rejoins(member_fk, rejoin_date, rejoin_start_fk, active_date_fk, end_date_fk, grade_fk, expiry_date_fk, membership_id, hub_fk, product_fk, organisation_fk)
SELECT
    r.member_fk,
    DATEADD(day, 7 + (ABS(CHECKSUM(NEWID())) % 60), r.start_date) AS rejoin_date,
    CAST(CONVERT(char(8), DATEADD(day, 7 + (ABS(CHECKSUM(NEWID())) % 60), r.start_date), 112) AS int),
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(r.start_date), MONTH(DATEADD(day, 7 + (ABS(CHECKSUM(NEWID())) % 60), r.start_date)), 1), 112) AS int),
    CAST(CONVERT(char(8), DATEFROMPARTS(YEAR(r.start_date), 12, 31), 112) AS int),
    r.grade_fk,
    r.expiry_date_fk,
    r.membership_id,
    r.hub_fk,
    r.product_fk,
    r.organisation_fk
FROM #Resigned r;

INSERT INTO dwh.fact_membership
(
    member_fk, organisation_fk, product_fk, grade_fk, prev_grade_fk, hub_fk, currency_fk,
    owner_fk, start_date_fk, expiry_date_fk, admit_to_membership_date_fk, cbc_document_date_fk,
    membership_id, membership_number, membership_number_grade_concat, membership_name,
    total_value, total_value_base, special_pricing, invoice_id, direct_debit_mandate,
    [state], [status], membership_status_original, membership_type_original,
    previous_membership_id, age_at_membership_start, age_group_at_membership_start,
    created_date, created_date_fk, modified_date, modified_date_fk,
    pending_date_fk, active_date_fk, end_date_fk, deleted_date_fk,
    membership_status_derived, membership_type_derived,
    is_admission, is_upgrade, is_reinstatement, is_attrition,
    no_of_company_professional_staff, Annual_Revenue_Band, contact_id, special_pricing_reason
)
SELECT
    r.member_fk, r.organisation_fk, r.product_fk, r.grade_fk, NULL, r.hub_fk, @BaseCurrencyFk,
    NULL, r.rejoin_start_fk, r.expiry_date_fk, r.rejoin_start_fk, NULL,
    r.membership_id,
    m.membership_number,
    CONCAT(m.membership_number, '+', r.grade_fk),
    CONCAT(m.first_name, ' ', m.last_name),
    CAST(0 AS decimal(38,4)),
    CAST(0 AS decimal(38,4)),
    'standard',
    NULL, NULL,
    'Active', 'Rejoin',
    'Active', 'Rejoin',
    NULL,
    DATEDIFF(year, m.date_of_birth, dd.[date]),
    CASE
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 25 AND 34 THEN '25 to 34'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 35 AND 44 THEN '35 to 44'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 45 AND 54 THEN '45 to 54'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) BETWEEN 55 AND 64 THEN '55 to 64'
        WHEN DATEDIFF(year, m.date_of_birth, dd.[date]) >= 65 THEN '65 and over'
        ELSE '18 to 24'
    END,
    SYSUTCDATETIME(), r.rejoin_start_fk, SYSUTCDATETIME(), r.rejoin_start_fk,
    NULL, r.active_date_fk, r.end_date_fk, NULL,
    'Active', 'Rejoin',
    0, 0, 1, 0,
    NULL, NULL, CONVERT(varchar(38), m.contact_id), 'standard'
FROM #Rejoins r
JOIN dwh.dim_member m ON m.id = r.member_fk
JOIN dwh.dim_date dd ON dd.date_id = r.rejoin_start_fk;

PRINT CONCAT('Rejoins inserted: ', @@ROWCOUNT);

/* ----------------------------------------------------------------------------
11) Renewals (keeps 7-char age bucket)
---------------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Renewals') IS NOT NULL DROP TABLE #Renewals;
CREATE TABLE #Renewals (
    member_fk int not null,
    grade_fk  int not null,
    product_fk int not null,
    hub_fk    int not null,
    start_date date not null,
    renewal_date date not null,
    renewal_date_fk int not null,
    price money not null,
    pay_method varchar(50) not null,
    invoice_id uniqueidentifier null
);

INSERT INTO #Renewals(member_fk, grade_fk, product_fk, hub_fk, start_date, renewal_date, renewal_date_fk, price, pay_method)
SELECT a.member_fk, a.grade_fk, a.product_fk, a.hub_fk, a.start_date,
       DATEADD(year, 1, a.start_date),
       CAST(CONVERT(char(8), DATEADD(year, 1, a.start_date), 112) AS int),
       CAST(a.price * (0.95 + ((ABS(CHECKSUM(NEWID())) % 1000000)/1000000.0)*0.10) AS money),
       a.pay_method
FROM #Admissions a
WHERE DATEADD(year, 1, a.start_date) BETWEEN @StartDate AND @EndDate;

PRINT CONCAT('Renewal candidates: ', @@ROWCOUNT);

IF OBJECT_ID('tempdb..#InvR') IS NOT NULL DROP TABLE #InvR;
CREATE TABLE #InvR (member_fk int primary key, invoice_id uniqueidentifier not null);

MERGE dwh.fact_invoice AS T
USING (
    SELECT r.member_fk, r.product_fk, r.renewal_date_fk, r.renewal_date, r.price
    FROM #Renewals r
) AS src
ON 1=2
WHEN NOT MATCHED THEN
    INSERT
    (
        member_fk, currency_fk, product_fk, invoice_date_fk, due_date_fk, billing_year_fk,
        organisation_fk, invoice_id, invoice_name, invoice_number, salesorderid, line_number,
        invoice_amount, outstanding_amount, quantity, unit_price, line_amount, discount_amount, vat_amount, extended_amount,
        [state], [status], invoice_type, invoice_detail_id, created_on_date_fk, modified_on_date_fk,
        is_renewal, is_floating_renewal, credit_allocated_invoice_name, bluemem_membershipgroupid
    )
    VALUES
    (
        src.member_fk, @BaseCurrencyFk, src.product_fk,
        src.renewal_date_fk,
        CAST(CONVERT(char(8), DATEADD(day, 30, src.renewal_date), 112) AS int),
        DATEPART(year, src.renewal_date),
        NULL,
        NEWID(),
        CONCAT('INV-R-', RIGHT(CONVERT(varchar(10), src.renewal_date_fk), 6), '-', src.member_fk, '-1'),
        CONCAT('INV-R-', RIGHT(CONVERT(varchar(10), src.renewal_date_fk), 6), '-', src.member_fk),
        NULL, 1,
        CAST(src.price AS decimal(38,4)), CAST(src.price AS decimal(38,4)), 1, CAST(src.price AS decimal(38,4)),
        CAST(src.price AS decimal(38,4)), CAST(0 AS decimal(38,2)), CAST(0 AS decimal(38,4)), CAST(src.price AS decimal(38,4)),
        'Active','Active','Invoice', NEWID(),
        src.renewal_date_fk, src.renewal_date_fk,
        1, 0, NULL, NULL
    )
OUTPUT src.member_fk, INSERTED.invoice_id
INTO #InvR(member_fk, invoice_id);

UPDATE r SET r.invoice_id = ir.invoice_id
FROM #Renewals r
JOIN #InvR ir ON ir.member_fk = r.member_fk;

-- one-off renewal payments
INSERT INTO dwh.fact_payment
(
    contact_fk, orgnisation_fk, currency_fk, hub_fk, member_fk, payment_date_fk, payment_created_date_fk,
    invoice_date_fk, payment_billing_year_fk, invoice_billing_year_fk, payment_id, payment_name,
    payment_amount, payment_amount_base, exchange_rate, payment_type, payment_state, payment_status,
    bacs_ref, payment_ref_no, provider_tx_auth_code, invoice_id, invoice_name, invoice_status,
    bluefun_recurringdonationid, is_renewal, is_floating_renewal, is_late_renewal
)
SELECT
    r.member_fk, NULL, @BaseCurrencyFk, r.hub_fk, r.member_fk,
    CAST(CONVERT(char(8), DATEADD(day, CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 75 THEN 0 ELSE (ABS(CHECKSUM(NEWID())) % 20) END, r.renewal_date), 112) AS int),
    r.renewal_date_fk,
    r.renewal_date_fk,
    DATEPART(year, r.renewal_date),
    DATEPART(year, r.renewal_date),
    NEWID(), CONCAT('PAY-R-', RIGHT(CONVERT(varchar(10), r.renewal_date_fk), 6), '-', r.member_fk),
    CAST(r.price AS decimal(38,4)), CAST(r.price AS decimal(38,4)), CAST(1.0 AS decimal(38,10)),
    'Online - Portal',
    'Active', CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 92 THEN 'Paid' ELSE 'Failed' END,
    NULL, NULL, NULL,
    r.invoice_id, NULL, 'Active',
    NULL, 1, 0, CASE WHEN (ABS(CHECKSUM(NEWID())) % 100) < 10 THEN 1 ELSE 0 END
FROM #Renewals r
WHERE r.pay_method <> 'Direct Debit (Monthly)';

-- monthly DD renewals
;WITH Months AS (
    SELECT 1 AS m UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
INSERT INTO dwh.fact_payment
(
    contact_fk, orgnisation_fk, currency_fk, hub_fk, member_fk, payment_date_fk, payment_created_date_fk,
    invoice_date_fk, payment_billing_year_fk, invoice_billing_year_fk, payment_id, payment_name,
    payment_amount, payment_amount_base, exchange_rate, payment_type, payment_state, payment_status,
    bacs_ref, payment_ref_no, provider_tx_auth_code, invoice_id, invoice_name, invoice_status,
    bluefun_recurringdonationid, is_renewal, is_floating_renewal, is_late_renewal
)
SELECT
    r.member_fk, NULL, @BaseCurrencyFk, r.hub_fk, r.member_fk,
    CAST(CONVERT(char(8),
        DATEADD(day,
            CASE WHEN DATEPART(WEEKDAY, DATEADD(month, m.m-1, r.renewal_date)) IN (1,7) THEN 2 ELSE 0 END +
            (ABS(CHECKSUM(NEWID())) % 2),
            DATEADD(month, m.m-1, r.renewal_date)
        ), 112) AS int),
    r.renewal_date_fk,
    r.renewal_date_fk,
    DATEPART(year, r.renewal_date),
    DATEPART(year, r.renewal_date),
    NEWID(), CONCAT('PAY-R-DD-', RIGHT(CONVERT(varchar(10), r.renewal_date_fk), 6), '-', r.member_fk, '-', m.m),
    CAST(r.price/12.0 AS decimal(38,4)), CAST(r.price/12.0 AS decimal(38,4)), CAST(1.0 AS decimal(38,10)),
    'Direct Debit (Monthly)',
    'Active', 'Paid',
    NULL, NULL, NULL,
    r.invoice_id, NULL, 'Active',
    NULL, 1, 0, 0
FROM #Renewals r
JOIN Months m ON 1=1
WHERE r.pay_method = 'Direct Debit (Monthly)';

-- fact_renewal (7-char age bucket)
INSERT INTO dwh.fact_renewal
(
    member_fk, grade_fk, original_grade_fk, currency_fk, product_fk, hub_fk, billing_year_fk, latest_payment_date_fk,
    membership_id, renewal_id, member_subs, member_subs_base, floating_member_subs, floating_member_subs_base,
    total_amount, total_amount_base, invoiced_amount, paid_amount, discount, is_paid, payment_type, is_late, days_late,
    member_age, member_age_bucket, is_renewal, is_floating_renewal,
    original_billing_member_subs, original_billing_member_subs_base,
    [original class], [original class reason], [current class], [current class reason], is_consol, membership_id2
)
SELECT
    r.member_fk, r.grade_fk, r.grade_fk, @BaseCurrencyFk, r.product_fk, r.hub_fk,
    DATEPART(year, r.renewal_date),
    (SELECT TOP 1 p.payment_date_fk FROM dwh.fact_payment p WHERE p.invoice_id = r.invoice_id ORDER BY p.payment_date_fk DESC),
    NEWID(), NEWID(),
    CAST(r.price AS decimal(38,4)), CAST(r.price AS decimal(38,4)),
    CAST(CASE WHEN pm.method='Direct Debit (Monthly)' THEN r.price ELSE 0 END AS decimal(38,4)),
    CAST(CASE WHEN pm.method='Direct Debit (Monthly)' THEN r.price ELSE 0 END AS decimal(38,4)),
    CAST(r.price AS decimal(38,2)), CAST(r.price AS decimal(38,4)),
    CAST(r.price AS decimal(38,2)),
    CAST((SELECT SUM(CASE WHEN p.payment_status='Paid' THEN p.payment_amount ELSE 0 END) FROM dwh.fact_payment p WHERE p.invoice_id = r.invoice_id) AS decimal(38,4)),
    CAST(0 AS decimal(38,2)),
    CASE WHEN EXISTS (SELECT 1 FROM dwh.fact_payment p WHERE p.invoice_id=r.invoice_id AND p.payment_status='Paid') THEN 1 ELSE 0 END,
    pm.method,
    CASE WHEN EXISTS (SELECT 1 FROM dwh.fact_payment p WHERE p.invoice_id=r.invoice_id AND p.is_late_renewal=1) THEN 1 ELSE 0 END,
    CASE WHEN EXISTS (SELECT 1 FROM dwh.fact_payment p WHERE p.invoice_id=r.invoice_id AND p.is_late_renewal=1)
         THEN ABS(CHECKSUM(NEWID())) % 60 ELSE 0 END,
    DATEDIFF(year, m.date_of_birth, r.renewal_date),
    CASE
        WHEN DATEDIFF(year, m.date_of_birth, r.renewal_date) BETWEEN 18 AND 24 THEN '18-24'
        WHEN DATEDIFF(year, m.date_of_birth, r.renewal_date) BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATEDIFF(year, m.date_of_birth, r.renewal_date) BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATEDIFF(year, m.date_of_birth, r.renewal_date) BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATEDIFF(year, m.date_of_birth, r.renewal_date) BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+' END,
    1, CASE WHEN pm.method='Direct Debit (Monthly)' THEN 1 ELSE 0 END,
    CAST(r.price AS decimal(38,4)), CAST(r.price AS decimal(38,4)),
    'Standard', NULL, 'Standard', NULL, 0, NULL
FROM #Renewals r
JOIN dwh.dim_member m ON m.id = r.member_fk
CROSS APPLY (SELECT TOP 1 method FROM #PayMix ORDER BY CASE WHEN method=r.pay_method THEN 0 ELSE 1 END, NEWID()) pm;

;WITH PaidR AS (
    SELECT p.invoice_id, SUM(CASE WHEN p.payment_status='Paid' THEN p.payment_amount ELSE 0 END) AS paid
    FROM dwh.fact_payment p
    GROUP BY p.invoice_id
)
UPDATE inv
SET outstanding_amount = CAST(inv.invoice_amount - ISNULL(p.paid,0) AS decimal(38,4))
FROM dwh.fact_invoice inv
LEFT JOIN PaidR p ON p.invoice_id = inv.invoice_id;

PRINT 'Renewals generated.';

/* ----------------------------------------------------------------------------
12) Mark run
---------------------------------------------------------------------------- */
INSERT INTO dwh.__synthetic_run(start_date, end_date) VALUES (@StartDate, @EndDate);
PRINT 'Synthetic generation complete.';
