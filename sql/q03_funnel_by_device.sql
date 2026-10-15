-- Q3. Does the funnel break differently on mobile vs desktop?
-- Concepts: nested STRUCT fields (device.category), ANY_VALUE, segment comparison
WITH sessions AS (
  SELECT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING)) AS session_key,
    ANY_VALUE(device.category)                AS device,
    LOGICAL_OR(event_name = 'view_item')      AS viewed_item,
    LOGICAL_OR(event_name = 'add_to_cart')    AS added_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout') AS began_checkout,
    LOGICAL_OR(event_name = 'purchase')       AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY session_key
)
SELECT
  device,
  COUNT(*)                                                                   AS sessions,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(viewed_item), COUNT(*)), 1)                AS view_item_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(added_to_cart), COUNT(*)), 1)              AS add_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(began_checkout), COUNT(*)), 2)             AS checkout_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)), 2)                  AS purchase_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(purchased), COUNTIF(added_to_cart)), 1)    AS cart_to_purchase_pct
FROM sessions
GROUP BY device
ORDER BY sessions DESC;
