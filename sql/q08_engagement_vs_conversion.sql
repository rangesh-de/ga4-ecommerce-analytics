-- Q8. How much engagement does a session need before people buy?
-- Concepts: summing engagement_time_msec, bucketing a continuous metric
WITH sessions AS (
  SELECT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING))  AS session_key,
    SUM((SELECT value.int_value FROM UNNEST(event_params)
         WHERE key = 'engagement_time_msec')) / 1000                       AS engaged_seconds,
    COUNTIF(event_name = 'page_view')                                      AS page_views,
    LOGICAL_OR(event_name = 'purchase')                                    AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY session_key
)
SELECT
  CASE
    WHEN engaged_seconds IS NULL OR engaged_seconds < 10 THEN '1. Under 10 sec'
    WHEN engaged_seconds < 60  THEN '2. 10-60 sec'
    WHEN engaged_seconds < 180 THEN '3. 1-3 min'
    WHEN engaged_seconds < 600 THEN '4. 3-10 min'
    ELSE '5. 10+ min'
  END                                                         AS engagement_bucket,
  COUNT(*)                                                    AS sessions,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)            AS share_of_sessions_pct,
  ROUND(AVG(page_views), 1)                                   AS avg_page_views,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)), 2)   AS conversion_pct
FROM sessions
GROUP BY engagement_bucket
ORDER BY engagement_bucket;
