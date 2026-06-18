# TravelTide — Customer Segmentation & RFM Analysis

> **RFM-based customer segmentation for a travel e-booking platform, with personalized loyalty perk recommendations per segment.**

---

## Business Context

TravelTide is a US-based e-booking startup (founded 2021) offering flight and hotel inventory. The project was commissioned by:

- **Kevin Talanick (CEO)** — improve customer retention through data-backed marketing
- **Elena Tarrant (Head of Marketing)** — design a personalized rewards program

The core problem: retention was weak, the customer base was not growing organically (87% of sign-ups occurred in a single quarter — Q1 2023), and there was no framework for targeting customers differently based on their behavior.

---

## Dataset at a Glance

| Metric | Value |
|---|---|
| Total customers | 5,998 |
| Avg spend per customer | $2,519 |
| Avg trips per customer | 2.6 |
| Avg sessions per customer | 8.2 |
| Session data window | March–August 2023 (160 days) |
| Features | 17 behavioral, demographic, transactional |
| Geography | USA + Canada |
| Missing/negative values | None in source (see [Corrections](#corrections)) |

---

## Repo Structure

```
traveltide-customer-segmentation/
├── README.md
├── CORRECTIONS.md              ← audit trail: what was fixed and why
├── sql/
│   └── tables_filtering.sql    ← data extraction and filtering queries
├── notebooks/
│   └── traveltide_analysis.ipynb   ← single canonical notebook (EDA → RFM → perks)
├── data/
│   ├── raw/
│   │   └── customers_ORIGINAL.csv  ← source feature table, unmodified
│   └── processed/
│       ├── rfm_ORIGINAL.xlsx       ← output before corrections (preserved for diff)
│       └── rfm_corrected.csv       ← corrected output (use this)
├── reports/
│   ├── TravelTide_Executive_Summary.docx
│   └── Final_TravelTide_BI_Analysis.pptx
└── requirements.txt
```

> **Note on raw data:** The full `sessions_table.xlsx` (~5.5 MB) and `users_table.xlsx` are not committed due to size. The `customers.csv` file is the aggregated feature table derived from those sources via the SQL in `sql/tables_filtering.sql`.

---

## Methodology

### Step 1: SQL Data Extraction
Raw sessions and users tables were joined and filtered in Databricks SQL to produce the `user_agg_features` table — one row per customer with pre-aggregated behavioral metrics.

See `sql/tables_filtering.sql` for the full query.

### Step 2: Exploratory Data Analysis
EDA was performed on both the users and sessions dimensions. Key findings are in the notebook and summarized in [Key Findings](#key-findings) below.

### Step 3: RFM Scoring

Customers were scored on three dimensions, each on a 1–3 scale using quantile-based binning (equal thirds):

| Dimension | Feature used | Direction |
|---|---|---|
| **Recency** | Days since last session (relative to dataset max date) | Lower = better = score 3 |
| **Frequency** | Number of trips booked | Higher = better = score 3 |
| **Monetary** | Total hotel + flight spend | Higher = better = score 3 |

**Important implementation note — recency reference date:**
Recency is calculated relative to the **dataset's most recent session date (2023-08-10)**, not today's date. Using today's date would make every customer appear dormant (1,042–1,202 days inactive), since the data is from 2023. See [`CORRECTIONS.md`](CORRECTIONS.md) for full details.

**Monetary NULLs:** 959 customers (16%) had no hotel spend. These were filled with $0 and flagged via `monetary_is_imputed = True`. Their monetary_score=1 assignment is correct — they are genuinely low-spend customers. Flight-only spenders are not captured in this metric; that is a known limitation.

### Step 4: Segment Assignment

Segmentation is driven primarily by the **Recency + Frequency** combination. Monetary score is applied selectively to two segments — **Promising** and **At Risk** — where spend level meaningfully changes the retention strategy (high-value vs. standard).

This was a deliberate design choice: for most segments, whether a customer spent $2k or $4k doesn't change the recommended perk; what matters is whether they're still active and how often they visit.

---

## Key Findings

### EDA — User Behavior

- **Bundled travel is the norm.** Flight and hotel booking profiles mirror each other almost exactly (both peak at ages 40–50). The same users book both — package upsells are broadly effective.
- **Core demographic is 35–55.** Under-30 representation is thin. UX and perks should target a mature, likely dual-income user.
- **Most users are low-frequency.** Trip counts cluster at 2–4, with very few power users. The retention lever is moving 1–2 trip customers toward 3–4.
- **Sign-up spike was not organic growth.** ~5,200 of 5,998 customers signed up in Q1 2023. This cohort is now 3 years old and drifting — retention is the only lever, not acquisition.

### EDA — Session Behavior

- **Fast converters spend the most.** Bookings above $10,000 almost exclusively occur in sessions under 10 minutes. Long sessions correlate with indecision, not intent. Priority: reduce checkout friction for high-intent users.
- **Two-thirds of sessions don't convert.** Only ~33% of sessions end in a booking. This warrants deeper funnel analysis beyond this project's scope.
- **Bundled bookings take 7+ minutes.** Hotel+flight sessions average 7+ minutes vs. ~2 minutes for single-service sessions — a signal of purchase intent worth targeting.

### Segmentation Results

| Segment | Customers | Avg LTV | Recency (days) | Avg Trips | Priority |
|---|---|---|---|---|---|
| Promising (High-Value) | 164 | $4,480 | 2 | 1.5 | ⭐ High |
| At Risk (High Value) | 186 | $4,187 | 25 | 2.8 | ⭐ High |
| Champions | 366 | $2,930 | 5 | 4.3 | High |
| Do Not Lose | 607 | $2,818 | 17 | 4.4 | ⭐ High |
| Loyal Customers | 841 | $2,654 | 7 | 4.5 | High |
| Potential Champions | 575 | $2,087 | 5 | 2.7 | Medium |
| Need Attention | 600 | $1,697 | 7 | 2.7 | Medium |
| About to Sleep | 373 | $954 | 7 | 1.6 | Low |
| At Risk | 453 | $911 | 20 | 2.6 | Low |
| Promising (Growth) | 709 | $688 | 3 | 1.3 | Low |
| Hibernating | 1,124 | $482 | 17 | 0.8 | Low |

> **Note on recency metric:** The clean notebook uses `time_after_booking` (days between last booking and last session) as the recency proxy — the only recency signal in the aggregated `customers.csv`. An earlier Phase 1 correction used `last_session_date` from the raw sessions table, which produces slightly different segment distributions. These figures reflect the canonical notebook output.

**Non-obvious insight — Value ≠ Frequency:**
At Risk (High Value) customers generate ~$1,503 revenue per trip, versus ~$596 for Loyal Customers. They are a hidden priority: retaining one At Risk HV customer protects 2.5× more revenue than retaining one Loyal Customer.

Do Not Lose represents ~$1.7M in revenue (607 customers × $2,818 avg LTV) with declining recency — the largest high-value pool quietly going inactive.

### Recommended Perks by Segment

| Segment | Recommended Action | Rationale |
|---|---|---|
| At Risk (High Value) | Aggressive win-back: 22% off + lounge access + concierge | Immediate churn risk; 22% discount consistent with PPT and perk output |
| Do Not Lose | Win-back: 18% off next 3 bookings + free upgrade | High LTV gone inactive — targeted re-engagement justified |
| Promising (High-Value) | Tiered loyalty benefits + early access to sales + free cancellation (2 bookings) | Highest avg LTV; premium nurturing to convert into Champions |
| Potential Champions | Frequency incentive: 10% off next 5 bookings + bundle deals + exclusive previews | High visits, low spend — monetization lever, not status play |
| Need Attention | Engagement bonus: 12% off + free baggage + loyalty enrolment incentive | Centre of LTV funnel; nudge toward repeat booking |
| Champions / Loyal | Loyalty rewards + quarterly exclusives + referral bonus | Protect existing behaviour; no aggressive spend needed |
| Bottom tier | Soft re-engagement only | Avg LTV under $1,000; minimise investment |

---

## Corrections

A post-submission audit identified three issues in the original notebook output. **Segment assignments were not affected** (scoring was quantile-based). Full details in [`CORRECTIONS.md`](CORRECTIONS.md).

| # | Issue | Impact on segments |
|---|---|---|
| 1 | Recency reference date used today (2026) instead of dataset max date (2023-08-10) | None — quantile scoring preserves relative rank |
| 2 | 959 NULL monetary values silently treated as $0 without flagging | None — already assigned lowest monetary score |
| 3 | One customer (user 549274) had monetary = -$5.78 | None — already in Hibernating |

---

## Next Steps

1. **Finalize retention budget** per segment to prioritize campaigns
2. **Run A/B test** — control (no perk) vs. treatment (segment-matched perk), tracking 90-day retention as primary KPI. Measure from day of perk delivery, not from sign-up date.
3. **Predictive modeling** — churn probability model on top of RFM scores to rank customers within each segment by urgency
4. **Investigate Q1 2023 spike** — identify the exact campaign/channel that drove it; test whether it can be replicated seasonally

---

## Tech Stack

- **SQL** (Databricks) — data extraction, filtering, feature aggregation
- **Python** (pandas, numpy) — EDA, RFM scoring, segmentation
- **Google Colab** — notebook environment
- **Excel / CSV** — intermediate outputs
- **Google Slides / PowerPoint** — final presentation

---

## How to Reproduce

1. Clone this repo
2. Install dependencies: `pip install -r requirements.txt`
3. Run `sql/tables_filtering.sql` against your Databricks workspace to reproduce the `user_agg_features` table, or use `data/raw/customers_ORIGINAL.csv` directly
4. Open `notebooks/traveltide_analysis.ipynb` and run all cells
5. Outputs will be written to `data/processed/`
