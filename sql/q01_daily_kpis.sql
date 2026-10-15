-- Q1. Daily users, sessions, purchases, revenue and conversion rate
-- Concepts: wildcard tables + _TABLE_SUFFIX, pulling a value out of event_params with UNNEST
WITH events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  day,
  COUNT(DISTINCT user_pseudo_id)                                             AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING)))         AS sessions,
  COUNTIF(event_name = 'purchase')                                           AS purchases,
  ROUND(SUM(IF(event_name = 'purchase', revenue, 0)), 2)                     AS revenue_usd,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(event_name = 'purchase'),
        COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING)))), 2) AS session_conversion_pct
FROM events
GROUP BY day
ORDER BY day;
