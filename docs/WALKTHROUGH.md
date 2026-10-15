# Query walkthrough

How each query works, the trap it avoids, and how to explain it in an interview. Run each CTE on its own in the BigQuery console and look at the output before adding the next one.

## Three patterns used everywhere

**1. Reading a parameter.** Event details are stored as a list of key/value pairs, not as columns:

```sql
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')
```

This opens the list for the current row, finds the one entry with that key, and returns its value. Pick the right type: `int_value` for IDs and numbers, `string_value` for URLs and text.

**2. Rebuilding sessions.** GA4 has no session table. `ga_session_id` is only unique per user, so a session key is `user_pseudo_id + ga_session_id`. Using `ga_session_id` alone merges different people's sessions together.

**3. Wildcard tables.** The data is one table per day (`events_20201101`, `events_20201102` ...). `events_*` queries them all, and `_TABLE_SUFFIX BETWEEN ...` limits which days are read. This is BigQuery's version of a partition filter, and it controls cost: fewer tables means less data scanned.

**Cost.** BigQuery bills by data scanned, not by time. It's columnar, so selecting fewer columns scans less. That's why none of these queries use `SELECT *`. Interview line: *"I always check the bytes estimate before running, and the runner script dry-runs every query to enforce a limit."*

## Q1. Daily KPIs

- One row per event, so sessions are counted as `COUNT(DISTINCT user + session_id)`, not `COUNT(*)`.
- `COUNTIF` is BigQuery's shorthand for counting rows matching a condition.
- `SAFE_DIVIDE` returns NULL instead of crashing when the denominator is 0.

## Q2. Purchase funnel

- Step 1 rolls events up to one row per session with true/false flags: did this session view an item, add to cart, and so on (`LOGICAL_OR` = "did it happen at least once").
- **Closed funnel:** a session only counts at "Began checkout" if it also viewed an item and added to cart. Without this, sessions that jump straight to checkout make some steps look bigger than the step before.
- The `UNNEST([STRUCT(...), ...])` trick turns one wide row into one row per step, so `LAG` can compute step-to-step conversion.
- **Interview line:** "The biggest drop tells you where to focus. A product page problem and a checkout problem need different fixes."

## Q3. Funnel by device

- `device.category` is a field inside a STRUCT, read with a dot.
- Compare `cart_to_purchase_pct` across devices. If mobile adds to cart at the same rate but buys less, the mobile checkout is the problem, not the products.

## Q4. Acquisition channels

- Works at **user** level. `traffic_source` is the channel that first brought the user (first-touch attribution).
- Ranks channels by revenue per user, not visitors. A channel with lots of visitors and no buyers is expensive traffic.
- **Know the limitation:** first-touch credits only the first channel, and in this sample many sources are obfuscated as `<Other>` or `(data deleted)`. Saying this unprompted shows maturity.

## Q5. Product performance

- `items` is an array. `FROM events, UNNEST(items) AS item` creates one row per product per event, so a product's views, carts and sales can be counted.
- High views + low view-to-cart = a product page problem (price, photos, description). High cart + low purchase = something happens at checkout (shipping cost, stock).

## Q6. Cart abandonment by category

- Uses item **quantities**: units added vs units purchased.
- It's a rough measure. A unit added in December and bought in January still counts, but it's directionally useful for spotting categories with problems.

## Q7. New vs returning

- `ga_session_number` = 1 for a user's first session, 2 for the second, and so on.
- Usually returning visitors convert much better, which is the business case for retargeting and email capture.

## Q8. Engagement vs conversion

- Adds up `engagement_time_msec` across a session's events (time the page was actually in focus).
- Buckets sessions by engaged time and compares conversion. This shows what "a good session" looks like.

## Q9. Time to first purchase

- `event_timestamp` is in microseconds. `TIMESTAMP_MICROS` converts it.
- `MIN(IF(event_name = 'purchase', event_timestamp, NULL))` = the first purchase time, because `MIN` ignores NULLs.
- **Business meaning:** if most buyers purchase on day one, the site must convert on the first visit. If many take a week, remarketing matters.
- **Limitation:** "first seen" is the first event inside this 3-month window, so users who visited before November look newer than they are.

## Q10. Landing pages

- `ARRAY_AGG(page_path ORDER BY event_timestamp LIMIT 1)[OFFSET(0)]` = the first page of each session. This is a standard BigQuery idiom for "first value per group".
- `REGEXP_EXTRACT` strips the domain and `?query` string, so `/basket.html?x=1` and `/basket.html` count as the same page.

## Q11. Weekly retention

- Same cohort logic as the Olist project, but in weeks: tag each user with their first active week, then measure the share active 1, 2, 3, 4 weeks later.
- `DATE_TRUNC(date, WEEK(MONDAY))` makes weeks start on Monday.
- The last cohorts are excluded because they can't be followed for 4 weeks yet.

## Q12. Bought together

- One row per (transaction, product), then join that table to itself on transaction ID to get every pair of products in the same order.
- `a.item < b.item` keeps each pair once (A+B, not also B+A) and drops an item paired with itself.
- `pct_of_a_orders_with_b` is called **confidence** in market basket analysis: of orders containing A, how many also contain B. That's the number behind "frequently bought together" recommendations.

## Questions an interviewer might ask

- *How is GA4 data different from a normal table?* One row per event, with nested arrays for parameters and products. You rebuild sessions and unnest arrays yourself.
- *How did you keep costs down?* `_TABLE_SUFFIX` filters, selecting only needed columns, and dry runs with a scan limit.
- *What would you do next?* A Looker Studio dashboard on the funnel and channel results, and materializing a sessions table so every query doesn't rebuild sessions from raw events.
