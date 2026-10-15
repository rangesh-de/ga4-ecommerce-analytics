# Setup: BigQuery sandbox

The dataset is public, but BigQuery runs queries under your own Google Cloud project. The sandbox is free and needs no credit card.

## 1. Create the sandbox project

1. Go to https://console.cloud.google.com/bigquery and sign in with your Google account.
2. Accept the terms. If asked, create a project (any name, for example `ga4-analytics`).
3. Note the **project ID** shown in the project picker at the top. It may differ from the name (for example `ga4-analytics-438712`).

You'll see a "Sandbox" banner. Limits: 1 TB of queries and 10 GB of storage per month, free. This project uses far less.

## 2. Check that it works

Paste this into the query editor and click **Run**:

```sql
SELECT COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';
```

Before you run it, the editor shows how much data the query will process (top right). Check this habit on every query.

## 3. (Optional) Run all queries from your computer

1. Install the Google Cloud CLI: https://cloud.google.com/sdk/docs/install
2. Log in so Python can use your account:

   ```bash
   gcloud auth application-default login
   ```

3. From the repo folder:

   ```bash
   pip install -r requirements.txt
   python scripts/run_analysis.py --project YOUR_PROJECT_ID
   ```

## Troubleshooting

- **"Access Denied" or "project not found":** use the project **ID**, not the display name.
- **"Could not automatically determine credentials":** run step 3.2 again.
- **A query is skipped for size:** raise the limit with `--max-gb 10`. These queries are small, so this should not happen.
