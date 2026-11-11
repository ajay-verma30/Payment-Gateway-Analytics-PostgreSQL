Synthetic payments dataset (31 tables) for payments_schema.sql
1. Create tables:   psql -d yourdb -f payments_schema.sql
2. Load data:       cd CSV Sheets folder; psql -d yourdb -f load_data.sql      (tables load in FK order)
   (pgAdmin/DBeaver: import each CSV, header=yes, NULL = empty, in the order listed in load_data.sql)
- Amounts are minor units (cents/paise). Timestamps are UTC. Window: 2025-11-01 .. 2026-10-31, as-of 2026-11-07.
- Dispute/fraud rates are deliberately inflated (~3% of captured charges) so every table has >= 2k rows.
- data_quality_answer_key.csv lists injected problems (duplicates, mismatches, incidents). Try to find them first!
- _row_counts.csv has the row count of every table.
