-- Q2. Where do shoppers drop out between landing and purchasing?
-- Concepts: session-level flags with LOGICAL_OR, closed funnel, unpivot with UNNEST of STRUCTs, LAG
WITH sessions AS (
  SELECT
    CONCAT(user_pseudo_id, CAST((SELECT value.int_value FROM UNNEST(event_params)
                                 WHERE key = 'ga_session_id') AS STRING)) AS session_key,
    LOGICAL_OR(event_name = 'view_item')        AS viewed_item,
    LOGICAL_OR(event_name = 'add_to_cart')      AS added_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout')   AS began_checkout,
    LOGICAL_OR(event_name = 'add_payment_info') AS added_payment,
    LOGICAL_OR(event_name = 'purchase')         AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY session_key
),
-- Closed funnel: a session only counts at a step if it also completed every earlier step
totals AS (
  SELECT
    COUNT(*)                                                                    AS s0,
    COUNTIF(viewed_item)                                                        AS s1,
    COUNTIF(viewed_item AND added_to_cart)                                      AS s2,
    COUNTIF(viewed_item AND added_to_cart AND began_checkout)                   AS s3,
    COUNTIF(viewed_item AND added_to_cart AND began_checkout AND added_payment) AS s4,
    COUNTIF(viewed_item AND added_to_cart AND began_checkout AND added_payment AND purchased) AS s5
  FROM sessions
),
steps AS (
  SELECT step.*
  FROM totals,
  UNNEST([
    STRUCT(0 AS step_order, 'All sessions'      AS step, s0 AS sessions),
    STRUCT(1, 'Viewed a product',  s1),
    STRUCT(2, 'Added to cart',     s2),
    STRUCT(3, 'Began checkout',    s3),
    STRUCT(4, 'Added payment',     s4),
    STRUCT(5, 'Purchased',         s5)
  ]) AS step
)
SELECT
  step_order,
  step,
  sessions,
  ROUND(100 * SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_order)), 1) AS pct_of_previous_step,
  ROUND(100 * SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER (ORDER BY step_order)), 2) AS pct_of_all_sessions
FROM steps
ORDER BY step_order;
