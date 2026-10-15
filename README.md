# GA4 E-commerce Product Analytics in BigQuery

Product analytics on Google Analytics 4 event data from the Google Merchandise Store (Nov 2020 – Jan 2021, about 4 million events), using BigQuery SQL. The work covers the purchase funnel, acquisition channels, product performance, engagement, retention and market basket analysis. These are the questions product and marketing analytics teams answer every week.

**Skills shown:** BigQuery, GA4 export schema, nested and repeated data (`UNNEST`, `STRUCT`, `ARRAY_AGG`), wildcard tables, sessionization, funnel and cohort analysis, market basket analysis, cost-aware querying.

## Key findings

> Fill this in after running the queries (see `results/SUMMARY.md`). Write 4–6 bullets, each as a number plus what the business should do about it. Example format:
> - **Only X% of shoppers who add to cart complete the purchase.** Biggest drop is at checkout, so the checkout flow is the first thing to test.

- 
- 
- 
- 

## Business questions

| # | Question | Main techniques |
|---|---|---|
| 1 | Daily users, sessions, revenue and conversion | Wildcard tables, `_TABLE_SUFFIX`, event_params lookup |
| 2 | Where do shoppers drop out of the purchase funnel? | Session flags with `LOGICAL_OR`, closed funnel, `LAG` |
| 3 | Does the funnel break differently on mobile vs desktop? | Nested `STRUCT` fields, segment comparison |
| 4 | Which channels bring buyers, not just visitors? | User-level first-touch attribution |
| 5 | Which products get viewed but not bought? | `UNNEST(items)`, product micro-funnel |
| 6 | Which categories have the worst cart abandonment? | Quantity comparison across event types |
| 7 | Do returning visitors convert better? | `ga_session_number` segmentation |
| 8 | How much engagement comes before a purchase? | Engagement time buckets |
| 9 | How long until a visitor's first purchase? | `TIMESTAMP_MICROS`, `TIMESTAMP_DIFF` |
| 10 | Which landing pages lead to sales? | First event per session with `ARRAY_AGG ... LIMIT 1` |
| 11 | What % of each week's new visitors come back? | Weekly cohorts, `DATE_DIFF(.., WEEK)` |
| 12 | Which products are bought together? | Self-join market basket, support and confidence |

Each query is in `sql/`. A plain-English explanation of every query is in [`docs/WALKTHROUGH.md`](docs/WALKTHROUGH.md).

## About the data

GA4 exports one row per **event** (page_view, add_to_cart, purchase ...), not one row per visit or order. Details live in nested fields:

- `event_params`: an array of key/value pairs (session ID, page URL, engagement time). Read with `(SELECT value.int_value FROM UNNEST(event_params) WHERE key = '...')`.
- `items`: an array of products on ecommerce events. Read with `CROSS JOIN UNNEST(items)`.
- `device`, `geo`, `traffic_source`, `ecommerce`: structs read with dot notation.

There is no session table. A session is rebuilt from `user_pseudo_id` + the `ga_session_id` parameter, which every query here does.

Google obfuscated parts of this sample, so some values appear as `<Other>`, `(data deleted)` or `(not set)`. Queries filter these where they would distort results.

## How to run it

See [`docs/SETUP.md`](docs/SETUP.md) for the 5-minute BigQuery sandbox setup (free, no credit card).

**Option A: in the browser.** Open the BigQuery console, paste any file from `sql/` and click Run.

**Option B: run everything and export results.**

```bash
pip install -r requirements.txt
gcloud auth application-default login
python scripts/run_analysis.py --project YOUR_PROJECT_ID
```

This writes `results/*.csv` and `results/SUMMARY.md`. Before each query it does a free dry run to check how much data the query will scan, and skips anything over 5 GB (`--max-gb` to change). The whole set costs nothing within the sandbox's free 1 TB/month.

## Project structure

```
├── docs/
│   ├── SETUP.md           BigQuery sandbox + authentication
│   └── WALKTHROUGH.md     How each query works, in plain English
├── results/               Query outputs + SUMMARY.md (generated)
├── scripts/run_analysis.py
└── sql/                   q01–q12, one file per question
```

## Data source

[GA4 obfuscated sample e-commerce dataset](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset), public on BigQuery as `bigquery-public-data.ga4_obfuscated_sample_ecommerce`.
