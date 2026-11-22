-- Weekly completed orders by cohort: volume, active SAIDs, delivery time and distances.
-- Project: dhub-glovo (billing). Tables: fulfillment-dwh-production.curated_data_shared_glovo.
-- Pre: 2026-10-05 to 2026-11-01 (7 days per week). Post: 2026-11-02 to 2026-11-21 (last week has 6 days).

WITH item7 AS (SELECT x FROM UNNEST([908709,908650,930738,911658,908738,908736,930557,908712,908617]) AS x),
target AS (SELECT x FROM UNNEST([852013,935268,707340,692234,629959,629913,629921,707351,647237,707173,756126,641208,921446,479938,802513,707544,566080,935635,934520,935661,935648,961393,952996,627028,886260,968952,908709,908650,930738,911658,908738,908736,930557,908712,908617,727417,727190,727201,630709,628050,726705,653243,582559,727370,726402,788135,726417,423098,657484,905774,730107,726474,788138,726444,544910,515894,515892,726508,537919,930644,729525,726992,727348,527574,726988,727004,727409,730114,730106,518099,727356,727492,726742,726423,727430,953814,726999,515876,727408,729586,729529,515934,726469,515877,855783,727271,727481,898957,727471,727221,953827,727211,726777,726498,855625,886587,727085,727392,855699,876048,727232,869921,912700,890151,834234,888330,932651,727148,624730,648154,624721,727113,625309,624761,726426,727118,625303,727127,727317,691618,727145,624765,799519,624711,727137,624757,434385,727231,799337,727131,799343,727133,727132,730908,840338,434380,799179,629484,624361,624771,627373,627388,629938,624780,629866,730354,730965,866154,650450,726437,727673,727345,799340,799342,799482,840431,648114,913974,726431,730922,727123,660964,790051,727507,727394,726930,811263,726811,565692,565701,726937,566572,928638,952345,726942,727548,730132,646125,647466,740784,639540,740773,727183,352880,727445,347075,727329,727738,727479,727311,727728,727716,727747,727216,347077,562399,727398,529556,730969,580507,338532]) AS x),
orders AS (
  SELECT o.global_order_id, o.report_date, od.store_address_id, od.order_city_name,
    o.is_preorder, o.order_queued_at, o.rider_dropped_off_at,
    o.actual_delivery_time_in_seconds, o.at_customer_time_in_seconds,
    o.pickup_distance_google_in_meters, o.dropoff_distance_google_in_meters
  FROM `fulfillment-dwh-production.curated_data_shared_glovo.logistics_orders__orders` o
  JOIN `fulfillment-dwh-production.curated_data_shared_glovo.order_descriptors__order_descriptors_v2` od
    ON CAST(od.order_id AS STRING) = CAST(o.global_order_id AS STRING)
   AND od.p_creation_date BETWEEN '2026-10-04' AND '2026-11-22'
  WHERE o.p_creation_date BETWEEN '2026-10-04' AND '2026-11-22'
    AND o.report_date BETWEEN '2026-10-05' AND '2026-11-21'
    AND o.delivery_status = 'completed'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY o.global_order_id ORDER BY od.store_address_id) = 1
),
target_cities AS (SELECT DISTINCT order_city_name FROM orders WHERE store_address_id IN (SELECT x FROM target)),
ext AS (
  SELECT *,
    CASE WHEN store_address_id IN (SELECT x FROM item7) THEN 'Item 7 Go'
         WHEN store_address_id IN (SELECT x FROM target) THEN 'Other Experiment'
         ELSE 'Normal' END AS cohort,
    CASE WHEN report_date <= '2026-11-01' THEN 'pre' ELSE 'post' END AS period,
    DATE_TRUNC(report_date, WEEK(MONDAY)) AS week_start,
    CASE WHEN is_preorder = TRUE
         THEN TIMESTAMP_DIFF(TIMESTAMP(rider_dropped_off_at), TIMESTAMP(order_queued_at), SECOND) / 60.0
         ELSE (actual_delivery_time_in_seconds + COALESCE(at_customer_time_in_seconds, 0)) / 60.0 END AS dt_min
  FROM orders
  WHERE order_city_name IN (SELECT order_city_name FROM target_cities)
)
SELECT cohort, period, week_start,
  CASE WHEN period = 'pre' THEN 7
       ELSE DATE_DIFF(LEAST(DATE_ADD(week_start, INTERVAL 6 DAY), DATE '2026-11-21'), week_start, DAY) + 1 END AS days_in_week,
  COUNT(DISTINCT global_order_id) AS completed_orders,
  COUNT(DISTINCT store_address_id) AS active_saids,
  ROUND(AVG(dt_min), 2) AS avg_dt_min,
  ROUND(SAFE_DIVIDE(COUNTIF(dt_min > 60), COUNT(*)) * 100, 2) AS dt60_pct,
  ROUND(AVG(pickup_distance_google_in_meters) / 1000, 3) AS avg_pickup_km,
  ROUND(AVG(dropoff_distance_google_in_meters) / 1000, 3) AS avg_dropoff_km
FROM ext
GROUP BY 1,2,3,4
ORDER BY 1,3;
