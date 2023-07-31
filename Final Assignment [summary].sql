-- Compute order_binary for the 30 day window after the test_start_date for the test named item_test_2

SELECT 
  test_assignment,
  COUNT(DISTINCT item_id)       AS items_in_group,
  SUM(order_binary_30d)         AS total_orders_30d
FROM 
    (
      SELECT 
        orders.item_id                       AS item_id,
        final_assignments.test_assignment    AS test_assignment,
        MAX(CASE WHEN (orders.paid_at >= final_assignments.test_start_date              -- The MAX() function is used to aggregate the binary values for each item within the same test_assignment. 
            AND DATE(orders.paid_at) - DATE(final_assignments.test_start_date) <= 30)
            THEN 1 ELSE 0 END)               AS order_binary_30d
      FROM 
        dsv1069.final_assignments
        
      LEFT OUTER JOIN 
        dsv1069.orders
      ON 
        final_assignments.item_id = orders.item_id
      WHERE
        test_number = 'item_test_2'
      GROUP BY
        orders.item_id,
        final_assignments.test_assignment
      ORDER BY
        orders.item_id
    ) item_level
GROUP BY
  test_assignment 
ORDER BY
  test_assignment 

-- Compute binary views and average views

SELECT 
  test_assignment,
  COUNT(DISTINCT item_id)                 AS items_in_group,
  SUM(view_binary_30d)                    AS viewed_items,
  SUM(views)                              AS views,
  SUM(views)/COUNT(DISTINCT item_id)      AS average_views_per_item
FROM 
  (
      SELECT 
        final_assignments.item_id             AS item_id,
        final_assignments.test_assignment     AS test_assignment,
        MAX(CASE WHEN (views.event_time >= final_assignments.test_start_date        -- -- The MAX() function is used to aggregate the binary values for each item within the same test_assignment. 
          AND DATE(views.event_time) - DATE(final_assignments.test_start_date) <= 30)
          THEN 1 ELSE 0 END)                  AS view_binary_30d,
        COUNT(views.event_id)                 AS views
      FROM 
      dsv1069.final_assignments
        LEFT OUTER JOIN 
          (
          SELECT 
            event_id,
            event_time,
            parameter_value    
          FROM
            dsv1069.events 
          WHERE 
            event_name = 'view_item'
          ) views
        ON CAST(final_assignments.item_id AS TEXT) = views.parameter_value    -- should be transformed to make JOIN and functions work
        AND 
          views.event_time >= final_assignments.test_start_date
        AND 
          DATE(views.event_time) - DATE(final_assignments.test_start_date) <= 30
      WHERE
        test_number = 'item_test_2'
      GROUP BY 
        final_assignments.item_id,
        final_assignments.test_assignment
  )  item_level
GROUP BY
  test_assignment