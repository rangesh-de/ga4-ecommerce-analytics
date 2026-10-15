# GA4 E-commerce Product Analytics in BigQuery

Product analytics on Google Analytics 4 event data from the Google Merchandise Store (Nov 2020 – Jan 2021, about 4 million events), using BigQuery SQL. The work covers the purchase funnel, acquisition channels, product performance, engagement, retention and market basket analysis. These are the questions product and marketing analytics teams answer every week.

**Skills shown:** BigQuery, GA4 export schema, nested and repeated data (`UNNEST`, `STRUCT`, `ARRAY_AGG`), wildcard tables, sessionization, funnel and cohort analysis, market basket analysis, cost-aware querying.

## Key findings

Google Merchandise Store, Nov 2020 – Jan 2021: 360,129 sessions, 4,848 of which ended in a purchase (1.35%), and $362K in revenue. The best single day was Cyber Monday (Nov 30) at $12.0K.

- **The biggest leak is at the very top.** 78.6% of sessions never view a single product. Of sessions that add to cart, 81% don't buy, but once checkout starts nearly half (47.8%) complete it. Getting visitors to a product page matters more than fixing checkout.
- **Returning visitors are worth 9× new ones.** Visitors on their 4th+ session convert at 4.69%, vs 0.68% on a first visit, and bring in $4.08 per session vs $0.47. Email capture and remarketing are the clearest growth levers.
- **Most sessions are bounces.** 53.6% of sessions last under 10 seconds and essentially never convert. Sessions of 10+ minutes convert at 28.3%. Engagement time is a strong signal for which visitors to retarget.
- **Mobile is not the problem.** Mobile converts as well as desktop (1.39% vs 1.32%, cart-to-purchase 32.8% vs 31.3%). A mobile redesign wouldn't be justified by this data.
- **One viral page brings traffic, not sales.** The Google Dino Game T-shirt page landed 18,449 sessions, but 58.5% left after one page and only 0.02% bought, vs 1.78% for visitors landing on the homepage. Traffic numbers alone would make this page look like a success.
- **Buyers decide fast, and holiday shoppers don't come back.** 63.8% of buyers purchase on their first day. Only 2.5% of late-December visitors returned the next week, vs 6.3% of early-November visitors, so holiday traffic needs a plan to bring people back after the season.
- **Paid search earns the least per visitor.** Google ads brought $0.75 per user and 2.8% of revenue, vs $0.96 per user from organic search, which brought 24.1%.

_Google obfuscates parts of this sample: some traffic sources show as "(data deleted)" or "<Other>", and some item quantities are scrambled. Category-level cart abandonment (Q6) was rebuilt to count events instead of quantities, but categories still come out at 87–99% abandonment, too flat to rank reliably._

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
