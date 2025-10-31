
/*
===============================================================================
MS-Copilot-AgenticRAG-Evaluation : Azure SQL - Schemas and Tables
Author: Riyaz Shaik
Purpose: Create schemas [dwh], [report] and all tables defined in the project.
Run order: Connect to your Azure SQL Database, then execute this script.
Notes:
 - Keeps column names exactly as provided (including spaces and typos).
 - No foreign keys are created yet. Add later if needed.
 - Execute in a tool that understands 'GO' batch separators (SSMS/Azure Data Studio/sqlcmd).
===============================================================================
*/

-- Create schemas if they do not exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dwh')
    EXEC('CREATE SCHEMA [dwh] AUTHORIZATION [dbo]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'report')
    EXEC('CREATE SCHEMA [report] AUTHORIZATION [dbo]');
GO

/* -------------------------------------------------------------------------- */
/* dwh.fact_membership                                                        */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[fact_membership](
	[membership_sk] [int] IDENTITY(1,1) NOT NULL,
	[member_fk] [int] NULL,
	[organisation_fk] [int] NULL,
	[product_fk] [int] NULL,
	[grade_fk] [int] NULL,
	[prev_grade_fk] [int] NULL,
	[hub_fk] [int] NULL,
	[currency_fk] [int] NULL,
	[owner_fk] [int] NULL,
	[start_date_fk] [int] NULL,
	[expiry_date_fk] [int] NULL,
	[admit_to_membership_date_fk] [int] NULL,
	[cbc_document_date_fk] [int] NULL,
	[membership_id] [uniqueidentifier] NULL,
	[membership_number] [varchar](400) NULL,
	[membership_number_grade_concat] [varchar](400) NULL,
	[membership_name] [varchar](max) NULL,
	[total_value] [decimal](38, 4) NULL,
	[total_value_base] [decimal](38, 4) NULL,
	[special_pricing] [varchar](400) NULL,
	[invoice_id] [uniqueidentifier] NULL,
	[direct_debit_mandate] [varchar](400) NULL,
	[state] [varchar](max) NULL,
	[status] [varchar](max) NULL,
	[membership_status_original] [varchar](400) NULL,
	[membership_type_original] [varchar](max) NULL,
	[previous_membership_id] [uniqueidentifier] NULL,
	[age_at_membership_start] [int] NULL,
	[age_group_at_membership_start] [varchar](11) NULL,
	[created_date] [datetimeoffset](7) NULL,
	[created_date_fk] [int] NULL,
	[modified_date] [datetime2](7) NULL,
	[modified_date_fk] [int] NULL,
	[pending_date_fk] [int] NULL,
	[active_date_fk] [int] NULL,
	[end_date_fk] [int] NULL,
	[deleted_date_fk] [int] NULL,
	[membership_status_derived] [varchar](max) NULL,
	[membership_type_derived] [varchar](max) NULL,
	[is_admission] [int] NULL,
	[is_upgrade] [int] NULL,
	[is_reinstatement] [int] NULL,
	[is_attrition] [int] NULL,
	[no_of_company_professional_staff] [nvarchar](100) NULL,
	[Annual_Revenue_Band] [varchar](max) NULL,
	[contact_id] [varchar](38) NULL,
	[special_pricing_reason] [varchar](max) NULL,
 CONSTRAINT [PK_membership_sk] PRIMARY KEY CLUSTERED 
(
	[membership_sk] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_date                                                               */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_date](
	[date_id] [varchar](8) NULL,
	[date] [datetime] NULL,
	[year] [int] NULL,
	[month_no] [int] NULL,
	[month_name] [nvarchar](30) NULL,
	[mth] [nvarchar](4000) NULL,
	[mth_year] [nvarchar](4000) NULL,
	[mth_year_no] [int] NULL,
	[day] [int] NULL,
	[weekday_no] [int] NULL,
	[weekday_name] [nvarchar](30) NULL,
	[quarter] [int] NULL,
	[years_from_today] [int] NULL,
	[months_from_today] [int] NULL,
	[weeks_from_today] [int] NULL,
	[days_from_today] [int] NULL,
	[week_no] [int] NULL,
	[weekend_date] [datetime] NULL,
	[past_date] [int] NULL,
	[renewal_month_sort] [int] NULL,
	[is_completed_month] [bit] NULL,
	[end_of_month] [date] NULL,
	[is_end_of_month] [bit] NULL,
	[qtr_year] [nvarchar](25) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dwh].[dim_date] ADD  DEFAULT ((0)) FOR [is_completed_month]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_grade                                                              */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_grade](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[grade_id] [uniqueidentifier] NULL,
	[grade_name] [varchar](400) NULL,
	[grade_type] [varchar](400) NULL,
	[paying] [varchar](255) NULL,
	[employed] [varchar](255) NULL,
	[student] [varchar](255) NULL,
	[status] [varchar](255) NULL,
	[grade_display] [varchar](255) NULL,
	[reporting_category] [varchar](20) NULL,
	[membership_category] [varchar](255) NULL,
	[parent_grade_name] [varchar](255) NULL,
	[performance_grade] [varchar](100) NULL
) ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_hub                                                                */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_hub](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[local_hub_id] [uniqueidentifier] NULL,
	[local_hub] [varchar](200) NULL,
	[area_hub_id] [int] NULL,
	[area_hub_name] [nvarchar](100) NULL,
	[regional_group_id] [uniqueidentifier] NULL,
	[regional_group] [varchar](200) NULL,
	[regional_hub_id] [uniqueidentifier] NULL,
	[regional_hub] [varchar](200) NULL,
	[super_region_id] [uniqueidentifier] NULL,
	[super_region] [varchar](200) NULL,
	[country_id] [uniqueidentifier] NULL,
	[country_name] [varchar](200) NULL,
	[economic_region_id] [uniqueidentifier] NULL,
	[economic_region] [varchar](200) NULL,
	[europe_international] [varchar](200) NULL,
	[status] [varchar](100) NULL,
	[state] [varchar](100) NULL,
	[region_code] [varchar](100) NULL
) ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_member                                                             */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_member](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[contact_id] [uniqueidentifier] NULL,
	[title] [varchar](400) NULL,
	[first_name] [nvarchar](max) NULL,
	[middle_name] [nvarchar](max) NULL,
	[last_name] [nvarchar](max) NULL,
	[full_name] [nvarchar](max) NULL,
	[certificate_name] [nvarchar](max) NULL,
	[salutation] [nvarchar](max) NULL,
	[job_title] [nvarchar](max) NULL,
	[gender] [varchar](max) NULL,
	[registered_disables_tatus] [varchar](6) NULL,
	[age] [int] NULL,
	[age_group] [varchar](11) NULL,
	[generation] [varchar](17) NULL,
	[membership_number] [varchar](400) NULL,
	[membership_grade] [varchar](400) NULL,
	[membership_status] [varchar](400) NULL,
	[parent_customer_id] [uniqueidentifier] NULL,
	[date_of_birth] [datetime2](7) NULL,
	[email_preferred] [varchar](400) NULL,
	[email_home] [varchar](400) NULL,
	[email_work] [varchar](400) NULL,
	[phone_preferred] [varchar](200) NULL,
	[phone_mobile] [varchar](200) NULL,
	[phone_home] [varchar](200) NULL,
	[phone_business] [varchar](200) NULL,
	[home_address_name] [nvarchar](max) NULL,
	[home_address_line_1] [nvarchar](max) NULL,
	[home_address_line_2] [nvarchar](max) NULL,
	[home_address_line_3] [nvarchar](max) NULL,
	[home_address_city] [nvarchar](max) NULL,
	[home_address_county] [nvarchar](max) NULL,
	[home_address_postal_code] [nvarchar](max) NULL,
	[home_address_country] [nvarchar](max) NULL,
	[home_address_latitude] [float] NULL,
	[home_address_longitude] [float] NULL,
	[work_address_name] [nvarchar](max) NULL,
	[work_address_line_1] [nvarchar](max) NULL,
	[work_address_line_2] [nvarchar](max) NULL,
	[work_address_line_3] [nvarchar](max) NULL,
	[work_address_city] [nvarchar](max) NULL,
	[work_address_county] [nvarchar](max) NULL,
	[work_address_postal_code] [nvarchar](max) NULL,
	[work_address_country] [nvarchar](max) NULL,
	[work_address_latitude] [float] NULL,
	[work_address_longitude] [float] NULL,
	[other_address_name] [nvarchar](max) NULL,
	[other_address_line_1] [nvarchar](max) NULL,
	[other_address_line_2] [nvarchar](max) NULL,
	[other_address_line_3] [nvarchar](max) NULL,
	[other_address_city] [nvarchar](max) NULL,
	[other_address_county] [nvarchar](max) NULL,
	[other_address_postal_code] [nvarchar](max) NULL,
	[other_address_country] [nvarchar](max) NULL,
	[status] [varchar](max) NULL,
	[portal_user_id] [varchar](400) NULL,
	[academy_id] [int] NULL,
	[academy_registration_date] [nvarchar](100) NULL,
	[is_ciob_member] [nvarchar](10) NULL,
	[academy_last_modified] [nvarchar](100) NULL,
	[academy_last_login] [nvarchar](100) NULL,
	[academy_disability_requirements] [nvarchar](200) NULL,
	[academy_other_requirements] [nvarchar](200) NULL,
	[academy_company_name] [nvarchar](1000) NULL,
	[academy_specialisms] [nvarchar](800) NULL,
	[academy_area_of_interest] [nvarchar](800) NULL,
	[academy_post_nominals] [varchar](1000) NULL,
	[date_joined] [datetime2](7) NULL,
	[modified_on] [datetime2](7) NULL,
	[modified_by] [uniqueidentifier] NULL,
	[contact_ref_no] [nvarchar](100) NULL,
	[tomorrows_leaders_community] [bit] NULL,
	[account_id] [uniqueidentifier] NULL,
	[preferred_membership_address_line_1] [nvarchar](max) NULL,
	[preferred_membership_address_line_2] [nvarchar](max) NULL,
	[preferred_membership_address_line_3] [nvarchar](max) NULL,
	[preferred_membership_address_city] [nvarchar](max) NULL,
	[preferred_membership_address_county] [nvarchar](max) NULL,
	[preferred_membership_address_postal_code] [nvarchar](max) NULL,
	[preferred_membership_address_country] [nvarchar](max) NULL,
	[chinese_title] [nvarchar](max) NULL,
	[chinese_firstname] [nvarchar](max) NULL,
	[chinese_lastname] [nvarchar](max) NULL,
	[chinese_fullname] [nvarchar](max) NULL,
	[CB] [nvarchar](25) NULL,
	[CCM] [nvarchar](25) NULL,
	[EmployerName] [varchar](640) NULL,
 CONSTRAINT [PK_id] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_product                                                            */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_product](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[product_id] [uniqueidentifier] NULL,
	[product_name] [varchar](500) NULL,
	[product_number] [varchar](400) NULL,
	[product_type] [varchar](400) NULL,
	[product_category] [nvarchar](400) NULL,
	[vat_rate] [varchar](400) NULL,
	[state] [varchar](400) NULL,
	[amount] [varchar](30) NULL,
	[amount_base] [varchar](30) NULL,
	[purchase_type] [varchar](100) NULL,
	[sold_externally] [varchar](10) NULL,
	[academy_product_id] [int] NULL,
	[grade] [int] NULL
) ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.fact_payment                                                           */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[fact_payment](
	[contact_fk] [int] NULL,
	[orgnisation_fk] [int] NULL,
	[currency_fk] [int] NULL,
	[hub_fk] [int] NULL,
	[member_fk] [int] NULL,
	[payment_date_fk] [int] NULL,
	[payment_created_date_fk] [int] NULL,
	[invoice_date_fk] [int] NULL,
	[payment_billing_year_fk] [int] NULL,
	[invoice_billing_year_fk] [int] NULL,
	[payment_id] [uniqueidentifier] NULL,
	[payment_name] [varchar](400) NULL,
	[payment_amount] [decimal](38, 4) NULL,
	[payment_amount_base] [decimal](38, 4) NULL,
	[exchange_rate] [decimal](38, 10) NULL,
	[payment_type] [varchar](400) NULL,
	[payment_state] [varchar](max) NULL,
	[payment_status] [varchar](max) NULL,
	[bacs_ref] [varchar](400) NULL,
	[payment_ref_no] [varchar](400) NULL,
	[provider_tx_auth_code] [varchar](400) NULL,
	[invoice_id] [uniqueidentifier] NULL,
	[invoice_name] [varchar](1200) NULL,
	[invoice_status] [varchar](max) NULL,
	[bluefun_recurringdonationid] [uniqueidentifier] NULL,
	[is_renewal] [int] NULL,
	[is_floating_renewal] [int] NULL,
	[is_late_renewal] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.fact_renewal                                                           */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[fact_renewal](
	[member_fk] [int] NULL,
	[grade_fk] [int] NULL,
	[original_grade_fk] [int] NULL,
	[currency_fk] [int] NULL,
	[product_fk] [int] NULL,
	[hub_fk] [int] NULL,
	[billing_year_fk] [int] NULL,
	[latest_payment_date_fk] [varchar](8) NULL,
	[membership_id] [uniqueidentifier] NULL,
	[renewal_id] [uniqueidentifier] NULL,
	[member_subs] [decimal](38, 4) NULL,
	[member_subs_base] [decimal](38, 4) NULL,
	[floating_member_subs] [decimal](38, 4) NULL,
	[floating_member_subs_base] [decimal](38, 4) NULL,
	[total_amount] [decimal](38, 2) NULL,
	[total_amount_base] [decimal](38, 4) NULL,
	[invoiced_amount] [decimal](38, 2) NULL,
	[paid_amount] [decimal](38, 4) NULL,
	[discount] [decimal](38, 2) NULL,
	[is_paid] [int] NOT NULL,
	[payment_type] [varchar](400) NULL,
	[is_late] [int] NOT NULL,
	[days_late] [int] NULL,
	[member_age] [int] NULL,
	[member_age_bucket] [varchar](7) NULL,
	[is_renewal] [int] NOT NULL,
	[is_floating_renewal] [int] NOT NULL,
	[original_billing_member_subs] [decimal](38, 4) NULL,
	[original_billing_member_subs_base] [decimal](38, 4) NULL,
	[original class] [varchar](400) NULL,
	[original class reason] [varchar](400) NULL,
	[current class] [varchar](400) NULL,
	[current class reason] [varchar](400) NULL,
	[is_consol] [bit] NULL,
	[membership_id2] [uniqueidentifier] NULL
) ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.fact_invoice                                                           */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[fact_invoice](
	[member_fk] [int] NULL,
	[currency_fk] [int] NULL,
	[product_fk] [int] NULL,
	[invoice_date_fk] [int] NULL,
	[due_date_fk] [int] NULL,
	[billing_year_fk] [int] NULL,
	[organisation_fk] [int] NULL,
	[invoice_id] [uniqueidentifier] NULL,
	[invoice_name] [nvarchar](100) NULL,
	[invoice_number] [nvarchar](100) NULL,
	[salesorderid] [uniqueidentifier] NULL,
	[line_number] [bigint] NULL,
	[invoice_amount] [decimal](38, 4) NULL,
	[outstanding_amount] [decimal](38, 4) NULL,
	[quantity] [decimal](38, 5) NULL,
	[unit_price] [decimal](38, 4) NULL,
	[line_amount] [decimal](38, 4) NULL,
	[discount_amount] [decimal](38, 2) NULL,
	[vat_amount] [decimal](38, 4) NULL,
	[extended_amount] [decimal](38, 4) NULL,
	[state] [varchar](max) NULL,
	[status] [varchar](max) NULL,
	[invoice_type] [varchar](max) NULL,
	[invoice_detail_id] [uniqueidentifier] NULL,
	[created_on_date_fk] [int] NULL,
	[modified_on_date_fk] [int] NULL,
	[is_renewal] [int] NOT NULL,
	[is_floating_renewal] [int] NOT NULL,
	[credit_allocated_invoice_name] [nvarchar](100) NULL,
	[bluemem_membershipgroupid] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/* -------------------------------------------------------------------------- */
/* dwh.dim_organisation                                                       */
/* -------------------------------------------------------------------------- */
CREATE TABLE [dwh].[dim_organisation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[organisation_id] [uniqueidentifier] NULL,
	[parent_id] [uniqueidentifier] NULL,
	[parent_organisation_id] [uniqueidentifier] NULL,
	[organisation_name] [nvarchar](max) NULL,
	[primary_contact] [nvarchar](max) NULL,
	[membership_number] [nvarchar](max) NULL,
	[membership_grade] [nvarchar](max) NULL,
	[membership_status] [varchar](400) NULL,
	[cbc_type] [varchar](max) NULL,
	[number_of_employees] [varchar](400) NULL,
	[is_study_centre] [varchar](6) NULL,
	[study_centre_type] [varchar](max) NULL,
	[is_exam_centre] [varchar](6) NULL,
	[study_centre_equiry_contact] [varchar](640) NULL,
	[study_centre_external_verifier] [varchar](640) NULL,
	[study_centre_lead_contact] [varchar](640) NULL,
	[email] [varchar](400) NULL,
	[website] [varchar](800) NULL,
	[phone_preference] [varchar](max) NULL,
	[phone_main] [varchar](200) NULL,
	[phone_other] [varchar](200) NULL,
	[address_name] [nvarchar](max) NULL,
	[address_city] [nvarchar](max) NULL,
	[address_full] [nvarchar](max) NULL,
	[address_country] [nvarchar](max) NULL,
	[address_county] [nvarchar](max) NULL,
	[address_latitude] [varchar](1000) NULL,
	[address_line1] [nvarchar](max) NULL,
	[address_line2] [nvarchar](max) NULL,
	[address_line3] [nvarchar](max) NULL,
	[address_longitude] [varchar](1000) NULL,
	[address_postalcode] [nvarchar](max) NULL,
	[address_province] [nvarchar](max) NULL,
	[industry_code] [varchar](400) NULL,
	[sic] [varchar](80) NULL,
	[ownership] [varchar](max) NULL,
	[territory] [varchar](800) NULL,
	[relationship_type] [varchar](max) NULL,
	[size] [varchar](max) NULL,
	[credit_limit] [varchar](400) NULL,
	[credit_on_hold] [varchar](6) NULL,
	[payment_terms] [varchar](max) NULL,
	[currency] [varchar](400) NULL,
	[local_hub] [varchar](400) NULL,
	[regional_hub] [varchar](400) NULL,
	[state] [varchar](700) NULL,
	[status] [varchar](700) NULL,
	[owner] [varchar](640) NULL,
	[renewal_documents_received_date] [datetime2](7) NULL,
	[is_tp] [int] NULL,
	[accredited_centre] [int] NULL,
	[annual_turnover] [varchar](max) NULL,
	[organisation_reference] [varchar](400) NULL,
	[invoicing_email] [varchar](400) NULL,
	[invoice_contact] [varchar](1000) NULL,
	[Responsible_Officer] [nvarchar](160) NULL,
	[Responsible_Officer_ContactID] [nvarchar](200) NULL,
	[tp_valid_from_fk] [int] NULL,
	[tp_valid_to_fk] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
