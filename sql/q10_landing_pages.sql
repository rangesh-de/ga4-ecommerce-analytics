-- Q10. Which landing pages start sessions that end in a sale?
-- Concepts: first event per session with ARRAY_AGG ... ORDER BY ... LIMIT 1, REGEXP_EXTRACT
WITH page_views AS (
  SELECT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING))  AS session_key,
    event_timestamp,
    REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params)
                    WHERE key = 'page_location'), r'^https?://[^/]+(/[^?#]*)') AS page_path
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'page_view'
),
landing AS (
  SELECT
    session_key,
    ARRAY_AGG(page_path ORDER BY event_timestamp LIMIT 1)[OFFSET(0)] AS landing_page,
    COUNT(*)                                                       AS page_views
  FROM page_views
  GROUP BY session_key
),
purchases AS (
  SELECT DISTINCT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING))  AS session_key
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)
SELECT
  l.landing_page,
  COUNT(*)                                                           AS sessions,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(l.page_views = 1), COUNT(*)), 1)   AS single_page_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(p.session_key IS NOT NULL), COUNT(*)), 2) AS conversion_pct
FROM landing l
LEFT JOIN purchases p USING (session_key)
WHERE l.landing_page IS NOT NULL
GROUP BY l.landing_page
HAVING COUNT(*) >= 1000
ORDER BY sessions DESC
LIMIT 20;
