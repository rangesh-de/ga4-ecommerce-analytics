-- Q9. How long does it take a visitor to make their first purchase?
-- Concepts: user-level MIN timestamps, TIMESTAMP_MICROS, TIMESTAMP_DIFF, bucketing
WITH users AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(MIN(event_timestamp))                                 AS first_seen,
    TIMESTAMP_MICROS(MIN(IF(event_name = 'purchase', event_timestamp, NULL))) AS first_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY user_pseudo_id
),
buyers AS (
  SELECT *, TIMESTAMP_DIFF(first_purchase, first_seen, HOUR) / 24 AS days_to_purchase
  FROM users
  WHERE first_purchase IS NOT NULL
)
SELECT
  CASE
    WHEN days_to_purchase < 1  THEN '1. Same day'
    WHEN days_to_purchase < 4  THEN '2. 1-3 days'
    WHEN days_to_purchase < 8  THEN '3. 4-7 days'
    WHEN days_to_purchase < 31 THEN '4. 8-30 days'
    ELSE '5. 31+ days'
  END                                                      AS time_to_purchase,
  COUNT(*)                                                 AS buyers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS share_of_buyers_pct,
  ROUND(100 * SUM(COUNT(*)) OVER (ORDER BY MIN(days_to_purchase))
        / SUM(COUNT(*)) OVER (), 1)                        AS cumulative_pct
FROM buyers
GROUP BY time_to_purchase
ORDER BY time_to_purchase;
