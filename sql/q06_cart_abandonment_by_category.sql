-- Q6. Which product categories have the worst cart abandonment?
-- Concepts: UNNEST(items), comparing quantities across event types
WITH category_qty AS (
  SELECT
    item.item_category                                           AS category,
    SUM(IF(event_name = 'add_to_cart', item.quantity, 0))        AS units_added,
    SUM(IF(event_name = 'purchase', item.quantity, 0))           AS units_purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('add_to_cart', 'purchase')
    AND item.item_category NOT IN ('(not set)', '')
  GROUP BY category
)
SELECT
  category,
  units_added,
  units_purchased,
  ROUND(100 * (1 - SAFE_DIVIDE(units_purchased, units_added)), 1) AS abandonment_pct
FROM category_qty
WHERE units_added >= 200
ORDER BY abandonment_pct DESC;
