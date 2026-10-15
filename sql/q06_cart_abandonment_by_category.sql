-- Q6. Which product categories have the worst cart abandonment?
-- Concepts: UNNEST(items), building a lookup table, working around obfuscated data
--
-- Two problems in this sample data had to be handled:
--   1. Purchase events don't carry item_category, so the category is looked up from
--      each product's view_item events (its most common category).
--   2. Some item quantities are obfuscated to huge values, so this counts item rows
--      (one per product per event) instead of summing quantity.
WITH product_category AS (
  SELECT item_name, category
  FROM (
    SELECT
      item.item_name AS item_name,
      item.item_category AS category,
      ROW_NUMBER() OVER (PARTITION BY item.item_name ORDER BY COUNT(*) DESC) AS rn
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
      AND event_name = 'view_item'
      AND item.item_category NOT IN ('(not set)', '')
    GROUP BY item_name, category
  )
  WHERE rn = 1
),
product_events AS (
  SELECT
    item.item_name AS item_name,
    COUNTIF(event_name = 'add_to_cart') AS cart_adds,
    COUNTIF(event_name = 'purchase')    AS purchases
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('add_to_cart', 'purchase')
    AND item.item_name NOT IN ('(not set)', '')
  GROUP BY item_name
)
SELECT
  c.category,
  SUM(e.cart_adds)                                                   AS cart_adds,
  SUM(e.purchases)                                                   AS purchases,
  ROUND(100 * (1 - SAFE_DIVIDE(SUM(e.purchases), SUM(e.cart_adds))), 1) AS abandonment_pct
FROM product_events e
JOIN product_category c USING (item_name)
GROUP BY c.category
HAVING SUM(e.cart_adds) >= 200
ORDER BY abandonment_pct DESC;
