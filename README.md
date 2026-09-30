# TravelTide: Customer Segmentation & Rewards Strategy with RFM Analysis

> RFM-based customer segmentation for a travel e-booking startup, translated into a segment-specific retention and rewards strategy.

![Python](https://img.shields.io/badge/Python-pandas%20%7C%20NumPy%20%7C%20Matplotlib-blue)
![SQL](https://img.shields.io/badge/SQL-Databricks-orange)
![Tableau](https://img.shields.io/badge/Dashboard-Tableau-lightblue)
![Status](https://img.shields.io/badge/Status-Complete-green)

---

## Table of Contents
1. [Situation](#1-situation)
2. [Task](#2-task)
3. [Actions](#3-actions)
4. [Results](#4-results)
5. [Recommendations](#5-recommendations)
6. [Tech Stack](#tech-stack)
7. [Repository Structure](#repository-structure)
8. [How to Reproduce](#how-to-reproduce)
9. [Data Notes & Limitations](#data-notes--limitations)

---

## 1. Situation

TravelTide is a US-based e-booking startup (founded 2021) offering flight and hotel inventory and search. The project responds to two stakeholders:

| Stakeholder | Goal |
|---|---|
| Kevin Talanick, CEO | Improve customer retention through data-backed marketing |
| Elena Tarrant, Head of Marketing | Design a personalized rewards program |

**Dataset:** 5,998 customers, 17 behavioral, demographic and transactional features (March–August 2023 session window).

| Metric | Value |
|---|---|
| Total customers | 5,998 |
| Avg. hotel spend per customer | $1,758 |
| Avg. trips per customer | 2.6 |
| Avg. sessions per customer | 8.2 |
| Geography | United States (4,991) and Canada (1,007) |
| Customers who never booked | 556 (9.3%) |

## 2. Task

Four objectives, addressed in four stages:

| # | Objective | Stage |
|---|---|---|
| 1 | Maximize customer lifetime value (LTV) | Exploratory Data Analysis (EDA) |
| 2 | Recommend personalized retention perks | Behavioral pattern analysis |
| 3 | Develop targeted engagement strategies | RFM segmentation framework |
| 4 | Identify customer segments that can be acted on | Perks recommendation and LTV analysis |

## 3. Actions

### Step 1: Data extraction (SQL)
Raw `users`, `sessions`, `flights` and `hotels` tables were filtered to active users using CTEs, then aggregated into one row per customer (`customers.csv`). See [`sql/tables_filtering.sql`](sql/tables_filtering.sql).

### Step 2: Exploratory data analysis (Python)
Data validation (nulls, duplicates), then EDA on two dimensions, user behavior and session behavior.

**User behavior**
- **Bundled travel is the norm.** Flight and hotel age profiles are nearly identical, so the same users book both. Package deals are a natural upsell.
- **Mature core audience.** Customers peak at ages 40–50 and under-30s are thin. Perks and UX should target this group.
- **Low-frequency bookers.** Most customers take 2–4 trips and there are very few power users. The retention lever is moving 1–2 trip customers to 3–4.
- **The sign-up spike was not organic.** About 5,200 of 5,998 customers (~87%) signed up in a single quarter (2023 Q1). Growth is not recurring, so retention matters most.

**Session behavior**
- **Fast converters spend the most.** Bookings above $10,000 occur almost exclusively in sessions under 10 minutes. Long sessions correlate with indecision.
- **Two-thirds of sessions do not convert.** Only about 1 in 3 sessions ends in a booking.
- **Bundled bookings take the longest** (7+ minutes), which signals high purchase intent.

### Step 3: RFM scoring

| Dimension | Feature | Scoring (1–3, quantile terciles) |
|---|---|---|
| **Recency** | `time_after_booking` (days between last booking and last session) | Fewer days = 3 |
| **Frequency** | `num_trips` | More trips = 3 |
| **Monetary** | `money_spent_hotel` (negatives clipped to 0) | Higher spend = 3 |

Customers who never booked are scored 1 on all three dimensions and placed in *Hibernating*.

### Step 4: Segment assignment
Segments are driven primarily by the **Recency + Frequency** combination. The **Monetary** score is applied selectively to two segments, *Promising* and *At Risk*. In those segments spend changes the right strategy: a high-value customer is worth an aggressive save, a low-value one is not.

11 segments result: Champions, Loyal Customers, Potential Champions, Need Attention, Do Not Lose, At Risk (High Value), At Risk, Promising (High-Value), Promising (Growth), About to Sleep, Hibernating.

## 4. Results

| Segment | Customers | Avg. LTV | Avg. recency (days) | Avg. trips | Revenue / trip | Priority |
|---|---:|---:|---:|---:|---:|---|
| Promising (High-Value) | 164 | $4,480 | 1.6 | 1.5 | $3,011 | High |
| At Risk (High Value) | 186 | $4,187 | 25.1 | 2.8 | $1,503 | High |
| Champions | 366 | $2,930 | 5.4 | 4.3 | $688 | High |
| Do Not Lose | 607 | $2,818 | 17.1 | 4.4 | $642 | High |
| Loyal Customers | 841 | $2,654 | 6.8 | 4.5 | $596 | High |
| Potential Champions | 575 | $2,087 | 5.0 | 2.7 | $779 | Medium |
| Need Attention | 600 | $1,697 | 6.8 | 2.7 | $626 | Medium |
| About to Sleep | 373 | $954 | 6.9 | 1.6 | $586 | Low |
| At Risk | 453 | $911 | 20.3 | 2.6 | $345 | Low |
| Promising (Growth) | 709 | $688 | 3.3 | 1.3 | $519 | Low |
| Hibernating | 1,124 | $482 | 16.6 | 0.8 | $640 | Low |

LTV here is total hotel spend per customer (see [Data Notes](#data-notes--limitations)).

**Key insights**
- **Value is not the same as frequency.** *At Risk (High Value)* customers generate about $1,503 per trip versus about $596 for *Loyal Customers*, roughly 2.5x. Retaining one of them protects more revenue.
- **Do Not Lose is the largest quiet revenue pool.** 607 customers with about $1.7M in lifetime spend and declining recency (17 days on average since last booking).
- **Promising (High-Value) confirms the strategy works.** It is a small segment (164 customers) with the highest LTV.
- **The bottom tier is low priority.** *Promising (Growth)*, *At Risk*, *About to Sleep* and *Hibernating* together hold about 17% of revenue, with per-customer LTV under $1,000. Minimize investment.
- **Potential Champions visit often but under-spend.** The play is monetization, not more visits.

## 5. Recommendations

| Segment | Action | Why |
|---|---|---|
| At Risk (High Value) | Aggressive win-back: 22% off, lounge access, concierge | Immediate churn risk on high-value customers |
| Do Not Lose | Win-back: 18% off next 3 bookings, free upgrade | High LTV, gone inactive |
| Promising (High-Value) | Tiered loyalty benefits, early access to sales, free cancellation | Highest LTV; convert into Champions |
| Potential Champions | 10% off next 5 bookings, bundle deals, exclusive previews | High visits, low spend |
| Need Attention | 12% off, free baggage, loyalty enrolment incentive | Center of the LTV funnel |
| Champions / Loyal | Loyalty rewards, quarterly exclusives, referral bonus | Protect existing behavior |
| Bottom tier | Soft re-engagement only | Low ROI |

**Next steps (recommended, not yet run)**
1. Finalize the budget for each segment campaign.
2. Predictive analysis of each campaign's impact, for example a churn-probability model layered on RFM scores.
3. **A/B test** segment-matched perks against a no-perk control, with 90-day retention as the primary KPI. Track KPIs by cohort.
4. Identify the campaign or channel behind the 2023 Q1 sign-up spike.

---

## Tech Stack

| Area | Tools |
|---|---|
| Data extraction and perk allocation | **SQL** (Databricks), CTEs, joins, aggregations |
| Analysis | **Python**: pandas, NumPy, Matplotlib, Seaborn |
| Notebooks | Jupyter / Google Colab |
| Dashboard | **Tableau** (`.twbx` workbooks: RFM segments, user perks, users, sessions) |
| Deliverables | Executive summary (Word), stakeholder presentation (PowerPoint / Google Slides) |
| Intermediate outputs | Excel / CSV |

## Repository Structure

```
traveltide-customer-segmentation/
├── README.md
├── CORRECTIONS.md                 # audit trail: what was fixed and why
├── requirements.txt
├── sql/
│   └── tables_filtering.sql       # data extraction and filtering
├── notebooks/
│   └── traveltide_analysis.ipynb  # EDA → RFM → segments → perks
├── data/
│   ├── raw/                       # customers_ORIGINAL.csv (unmodified)
│   └── processed/                 # rfm_corrected.csv, rfm_ORIGINAL.xlsx
├── dashboards/                    # Tableau workbooks (.twbx)
└── reports/
    ├── TravelTide_Executive_Summary.docx
    └── Final_TravelTide_BI_Analysis.pptx
```

Full `sessions` and `users` tables are not committed because of file size. `customers.csv` is the aggregated feature table derived from them.

## Data Notes & Limitations

- **Monetary = hotel spend only.** `money_spent_hotel` is the monetary proxy. Flight spend is not captured, so flight-heavy customers are under-valued. The "$1,758 average spend" is average hotel spend across all 5,998 customers, including 959 with no hotel spend (treated as $0).
- **Recency proxy.** The aggregated table has no last-booking date, so `time_after_booking` stands in for recency.
- **Corrections after submission.** A post-submission review fixed the recency reference date, the handling of customers with no hotel spend, and one negative spend value. Segment assignments were unchanged. Details are in [`CORRECTIONS.md`](CORRECTIONS.md).
- **Perks are recommendations.** No campaign or A/B test has been run, so no retention impact is measured.

---
