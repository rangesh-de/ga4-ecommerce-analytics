-- Q11. What % of each week's new visitors come back in the following weeks?
-- Concepts: cohort by first-seen week, DATE_TRUNC(.., WEEK(MONDAY)), DATE_DIFF in weeks
WITH activity AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS active_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
cohorts AS (
  SELECT user_pseudo_id, MIN(active_week) AS cohort_week
  FROM activity
  GROUP BY user_pseudo_id
),
joined AS (
  SELECT c.cohort_week, a.user_pseudo_id, DATE_DIFF(a.active_week, c.cohort_week, WEEK) AS week_number
  FROM activity a
  JOIN cohorts c USING (user_pseudo_id)
)
SELECT
  cohort_week,
  COUNT(DISTINCT IF(week_number = 0, user_pseudo_id, NULL)) AS new_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT IF(week_number = 1, user_pseudo_id, NULL)),
                          COUNT(DISTINCT IF(week_number = 0, user_pseudo_id, NULL))), 2) AS week_1_pct,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT IF(week_number = 2, user_pseudo_id, NULL)),
                          COUNT(DISTINCT IF(week_number = 0, user_pseudo_id, NULL))), 2) AS week_2_pct,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT IF(week_number = 3, user_pseudo_id, NULL)),
                          COUNT(DISTINCT IF(week_number = 0, user_pseudo_id, NULL))), 2) AS week_3_pct,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT IF(week_number = 4, user_pseudo_id, NULL)),
                          COUNT(DISTINCT IF(week_number = 0, user_pseudo_id, NULL))), 2) AS week_4_pct
FROM joined
-- First week is partial and the last cohorts can't be followed for 4 weeks
WHERE cohort_week BETWEEN '2020-11-02' AND '2020-12-28'
GROUP BY cohort_week
ORDER BY cohort_week;
