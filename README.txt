================================================================================

💳 PAYMENT GATEWAY ANALYTICS & POSTGRESQL AUDIT SUITE

================================================================================



OVERVIEW

--------

A comprehensive, production-grade synthetic payments dataset consisting of 31 

relational tables designed for advanced SQL data analysis, financial auditing, 

pipeline debugging, and performance reporting.



This repository includes the schema definition, automated loading scripts, raw CSV 

data sheets, anomaly documentation, and a complete suite of analytical queries 

located in `payment.sql`.





================================================================================

⚙️ QUICK SETUP & INSTALLATION

================================================================================



1. Create Database Schema

-------------------------

Run the schema setup script in your PostgreSQL environment to initialize all 31 

tables, constraints, and foreign key relationships:



   $ psql -d yourdb -f payments_schema.sql



2. Load Dataset

---------------

Navigate into the 'CSV Sheets' directory and execute the data loader script. 

Note: Tables are structured to load strictly in Foreign Key dependency order.



   $ cd "CSV Sheets"

   $ psql -d yourdb -f load_data.sql



GUI Alternative (pgAdmin / DBeaver / Datagrip):

------------------------------------------------

If importing manually via GUI tools, use the following settings for each CSV:

  - Header: Enabled (yes)

  - NULL Values: Empty string ("")

  - Execution Order: Follow the exact table sequence listed in load_data.sql





================================================================================

📊 DATASET SPECIFICATIONS & CORE RULES

================================================================================



* Currency & Financial Amounts: 

  All monetary values are stored in minor units (e.g., cents for USD/EUR, paise 

  for INR). Ensure appropriate division (amount / 100.0) when calculating major 

  currency units in SQL queries.



* Timestamps & Timezones: 

  All temporal records are normalized to UTC.

  - Operational Window : 2025-11-01 to 2026-10-31

  - Snapshot As-of Date: 2026-11-07



* Stress-Testing & Dispute Metrics:

  Dispute and fraud frequencies are intentionally inflated (~3.0% of captured 

  charges) to guarantee robust sample sizes (>= 2,000 rows across analytical 

  tables) for stress testing query performance.





================================================================================

🕵️ DATA QUALITY CONTROL & ANOMALY AUDITING

================================================================================



To test diagnostic skills and analytical precision, the dataset includes built-in 

edge cases:



* data_quality_answer_key.csv:

  Contains pre-injected data anomalies (such as referential mismatches, 

  duplicated entries, and system incident flags). Try discovering them using 

  SQL queries before cross-referencing this answer key!



* _row_counts.csv:

  A master reference file containing verified row counts for all 31 tables 

  to validate successful data ingestion.





================================================================================

📂 REPOSITORY ARCHITECTURE

================================================================================



├── payments_schema.sql             # PostgreSQL DDL for all 31 tables & constraints

├── payment.sql                     # Curated analytical SQL queries (Q1 - Q30+)

├── CSV Sheets/

│   ├── load_data.sql               # Automated bulk-insert order script

│   ├── _row_counts.csv             # Table-wise row count validation sheet

│   ├── data_quality_answer_key.csv # Documented data quality anomalies & insights

│   └── *.csv                       # Individual table source data files

└── README.txt                      # Project documentation





================================================================================

💡 ANALYTICAL QUERY SUITE (payment.sql SUMMARY)

================================================================================



The accompanying `payment.sql` file contains 30+ optimized PostgreSQL queries:

1. Merchant Portfolio Analytics: Status distribution, regional groupings, currency defaults.

2. Revenue & Transaction Processing: Monthly growth velocity, currency-wise metrics.

3. Payment Instrument Analysis: Cards, Wallets, UPI, SEPA, ACH, iDEAL penetration.

4. Failure & Risk Diagnostics: Currency-wise failure rates, high-friction merchant identification.

5. Complex Analytics: Merchant AOV, CTEs with CROSS JOIN overall averages, conditional aggregations (FILTER), and refund percentage metrics.

================================================================================