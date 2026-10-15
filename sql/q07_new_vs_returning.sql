-- Q7. Do returning visitors convert better than new ones?
-- Concepts: ga_session_number parameter, segmenting sessions
WITH sessions AS (
  SELECT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING))  AS session_key,
    MAX((SELECT value.int_value FROM UNNEST(event_params)
         WHERE key = 'ga_session_number'))                                 AS session_number,
    LOGICAL_OR(event_name = 'purchase')                                    AS purchased,
    SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY session_key
)
SELECT
  CASE
    WHEN session_number = 1 THEN '1. New (first session)'
    WHEN session_number BETWEEN 2 AND 3 THEN '2. Returning (2-3 sessions)'
    WHEN session_number >= 4 THEN '3. Loyal (4+ sessions)'
    ELSE '4. Unknown'
  END                                                         AS visitor_type,
  COUNT(*)                                                    AS sessions,
  COUNTIF(purchased)                                          AS purchase_sessions,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)), 2)   AS conversion_pct,
  ROUND(SAFE_DIVIDE(SUM(revenue), COUNT(*)), 2)               AS revenue_per_session
FROM sessions
GROUP BY visitor_type
ORDER BY visitor_type;
