-- Q12. Which products are bought together? (input for "frequently bought together" recommendations)
-- Concepts: market basket analysis, self-join on transaction, support and confidence
WITH baskets AS (
  SELECT DISTINCT
    ecommerce.transaction_id AS transaction_id,
    item.item_name           AS item
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND ecommerce.transaction_id NOT IN ('(not set)', '')
    AND item.item_name NOT IN ('(not set)', '')
),
item_counts AS (
  SELECT item, COUNT(*) AS item_orders
  FROM baskets
  GROUP BY item
),
pairs AS (
  SELECT a.item AS item_a, b.item AS item_b, COUNT(*) AS orders_together
  FROM baskets a
  JOIN baskets b
    ON a.transaction_id = b.transaction_id
   AND a.item < b.item                       -- each pair once, no item paired with itself
  GROUP BY item_a, item_b
)
SELECT
  p.item_a,
  p.item_b,
  p.orders_together,
  ROUND(100 * SAFE_DIVIDE(p.orders_together, ca.item_orders), 1) AS pct_of_a_orders_with_b,
  ROUND(100 * SAFE_DIVIDE(p.orders_together, cb.item_orders), 1) AS pct_of_b_orders_with_a
FROM pairs p
JOIN item_counts ca ON ca.item = p.item_a
JOIN item_counts cb ON cb.item = p.item_b
WHERE p.orders_together >= 10
ORDER BY p.orders_together DESC
LIMIT 20;
