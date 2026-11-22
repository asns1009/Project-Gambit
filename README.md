# Project Gambit: SAID saturation analysis

Pre/post analysis of Glovo partner SAIDs in Nigeria. Local teams drew non-overlapping partner radii, and this project measures whether saturation-driven radius shrinkage and closures affect demand.

## Setup

- Experiment SAID list: 201 SAIDs. Item 7 Go is 9 Ibadan SAIDs, and Other Experiment is the remaining 192.
- Go-live: 2026-11-02.
- Pre window: 2026-10-05 to 2026-11-01 (4 full Monday-to-Sunday weeks).
- Post window: 2026-11-02 to 2026-11-21 (20 days; the last week is partial, 6 days).
- Project: `dhub-glovo` (billing). Source tables: `fulfillment-dwh-production.curated_data_shared_glovo`.

## Files

- `sql/saturation_by_cohort.sql`: shrinkage and closure sessions by cohort and week, with zones mapped to cohorts.
- `sql/weekly_orders_by_cohort.sql`: completed orders, active SAIDs, delivery time and distances by cohort and week.

## Caveats

- Saturation is zone-level. Cohort saturation is inferred from the zones the cohort SAIDs sit in.
- Item 7 Go is one zone (Ibd). Post-period results are indicative only.
- Classification thresholds (shrinkage, closure, minimum sessions) are not yet set.
