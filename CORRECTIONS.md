# Corrections Log

This file documents issues identified in the original notebook output during a post-submission audit. It exists to show analytical rigour: catching and explaining errors is part of good data work.

**Original files are preserved unmodified in `data/processed/rfm_ORIGINAL.xlsx` and `data/raw/customers_ORIGINAL.csv` for reference.**

---

## Correction 1 — Recency Reference Date

### What was wrong

The original notebook calculated `days_since_last_session` using today's date as the reference point:

```python
# ORIGINAL (incorrect)
df['days_since_last_session'] = (pd.Timestamp.today() - df['last_session_date']).dt.days
```

Since the notebook was last run in June 2026 but the dataset covers March–August 2023, every customer appeared to have been inactive for 1,042–1,202 days (~3 years). This made Champions — the most recently active customers — look dormant.

**Original output (before fix):**

| Segment | days_since_last_session (min–max) |
|---|---|
| Champions | 1,042 – 1,065 days |
| Hibernating | 1,089 – 1,202 days |

### What was fixed

Recency is now calculated relative to the **dataset's most recent session date (2023-08-10)**:

```python
# CORRECTED
reference_date = df['last_session_date'].max()  # 2023-08-10
df['days_since_last_session'] = (reference_date - df['last_session_date']).dt.days
```

**After fix:**

| Segment | days_since_last_session (min–max) | Interpretation |
|---|---|---|
| Champions | 0 – 23 days | Active in the final 3 weeks of the dataset period |
| Potential Champions | 1 – 23 days | Same recency band as Champions |
| Loyal / Need Attention | 23 – 46 days | Active ~1 month before dataset end |
| At Risk variants / Do Not Lose | 47 – 141 days | Inactive 7 weeks to 4.5 months |
| Hibernating | 47 – 160 days | Inactive up to 5 months within dataset window |

### Impact on segment assignments

**None.** The original scoring used `pd.qcut` (quantile-based binning into equal thirds). Quantile scoring preserves relative rank — whether you shift all values by 1,042 or not, the third of customers with the lowest days still get `recency_score = 3`. Verified: 5,998/5,998 customers retain their original segment assignment.

### Why it still matters

- A reviewer reading `days_since_last_session = 1042` for a Champion will flag it immediately as broken output.
- It signals the notebook wasn't sanity-checked after running.
- The corrected values tell a meaningful business story: a Champion's last session was within the final 3 weeks of the data collection window.

---

## Correction 2 — Monetary NULL Handling

### What was wrong

959 customers (16.0%) had `total_monetary_value = NULL` in the original RFM output. These customers had no hotel spend recorded. They were silently assigned `monetary_score = 1` (lowest tier) without any flag or documentation.

There are two sub-groups within these 959:
- **505 customers** with genuinely zero travel activity (0 trips, 0 flights)
- **454 customers** with flight activity but no hotel spend (flight-only bookers)

### What was fixed

```python
# CORRECTED
df['monetary_is_imputed'] = df['total_monetary_value'].isna()  # transparent flag
df['total_monetary_value'] = df['total_monetary_value'].fillna(0).clip(lower=0)
```

The `rfm_corrected.csv` output includes a `monetary_is_imputed` column (`True` for these 959 customers).

### Impact on segment assignments

**None.** These 959 customers were already distributed across lower segments (Hibernating: 360, About to Sleep: 273, Promising Growth: 245) — exactly where $0 monetary value should place them.

### Known limitation this surfaces

For the 454 flight-only bookers, their true monetary value IS non-zero — it's captured in flight spend, not hotel spend. The `money_spent_hotel` column was used as the monetary proxy, which understates value for flight-heavy customers. A more complete monetary metric would be `money_spent_hotel + (num_flights × avg_flight_fare)`. This is noted as a limitation in the methodology.

---

## Correction 3 — Negative Monetary Value

### What was wrong

One customer (user ID: `549274`) had `total_monetary_value = -$5.78`. This is a discount artifact — a refund or discount amount exceeded the recorded spend. It was not caught in the original data cleaning step.

### What was fixed

```python
df['total_monetary_value'] = df['total_monetary_value'].clip(lower=0)
```

### Impact on segment assignments

**None.** This customer was already in the Hibernating segment and remains there.

---

## Summary Table

| # | Issue | File affected | Segment changes | Fix applied |
|---|---|---|---|---|
| 1 | Recency reference date = today instead of dataset max | rfm_ORIGINAL.xlsx | 0 of 5,998 | `reference_date = df['last_session_date'].max()` |
| 2 | 959 NULL monetary values not flagged | rfm_ORIGINAL.xlsx | 0 of 5,998 | `fillna(0)` + `monetary_is_imputed` flag |
| 3 | User 549274 has monetary = -$5.78 | rfm_ORIGINAL.xlsx | 0 of 5,998 | `clip(lower=0)` |

All corrected outputs are in `data/processed/rfm_corrected.csv`. Original outputs are preserved in `data/processed/rfm_ORIGINAL.xlsx`.
