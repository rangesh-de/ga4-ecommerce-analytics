-- Q4. Which acquisition channels bring buyers, not just visitors?
-- Concepts: user-level aggregation, first-touch attribution (traffic_source), revenue per user
WITH users AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(traffic_source.medium)                         AS medium,
    ANY_VALUE(traffic_source.source)                         AS source,
    COUNTIF(event_name = 'purchase')                         AS purchases,
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY user_pseudo_id
)
SELECT
  medium,
  source,
  COUNT(*)                                                    AS users,
  COUNTIF(purchases > 0)                                      AS purchasers,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchases > 0), COUNT(*)), 2) AS user_conversion_pct,
  ROUND(SUM(revenue), 2)                                      AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue), COUNT(*)), 2)               AS revenue_per_user,
  ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)    AS share_of_revenue_pct
FROM users
GROUP BY medium, source
HAVING COUNT(*) >= 500
ORDER BY revenue_usd DESC;
