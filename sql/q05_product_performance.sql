-- Q5. Which products get looked at but not bought?
-- Concepts: UNNEST(items) to explode the nested product array, per-product micro-funnel
WITH item_events AS (
  SELECT event_name, item.item_name, item.quantity, item.item_revenue_in_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'purchase')
    AND item.item_name NOT IN ('(not set)', '')
)
SELECT
  item_name,
  COUNTIF(event_name = 'view_item')                                      AS views,
  COUNTIF(event_name = 'add_to_cart')                                    AS add_to_carts,
  SUM(IF(event_name = 'purchase', quantity, 0))                          AS units_sold,
  ROUND(SUM(IF(event_name = 'purchase', item_revenue_in_usd, 0)), 2)     AS revenue_usd,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(event_name = 'add_to_cart'),
                          COUNTIF(event_name = 'view_item')), 1)         AS view_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(event_name = 'purchase'),
                          COUNTIF(event_name = 'view_item')), 2)         AS view_to_purchase_pct
FROM item_events
GROUP BY item_name
HAVING views >= 500
ORDER BY revenue_usd DESC
LIMIT 25;
