-- Q1 — Order volume by status


SELECT 
  order_status,
  COUNT(*) AS total_orders,

  ROUND(
    CAST(
      COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
      AS numeric
    ), 
    2
  ) AS pct

FROM olist_orders_dataset

GROUP BY order_status
ORDER BY total_orders DESC;



-- Q2 — Total revenue analysis

SELECT 
  ROUND(CAST(SUM(op.payment_value) AS numeric), 2) AS total_revenue,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(CAST(AVG(op.payment_value) AS numeric), 2) AS avg_order_value

FROM olist_orders_dataset o

JOIN olist_order_payments_dataset op 
  ON o.order_id = op.order_id

WHERE o.order_status = 'delivered';



-- Q3 — Top 10 product categories by order volume

SELECT 
  t.product_category_name_english AS category,

  COUNT(DISTINCT oi.order_id) AS total_orders,

  ROUND(CAST(SUM(oi.price) AS numeric), 2) AS total_revenue

FROM olist_order_items_dataset oi

JOIN olist_products_dataset p 
  ON oi.product_id = p.product_id

JOIN product_category_name_translation t 
  ON p.product_category_name = t.product_category_name

GROUP BY category
ORDER BY total_orders DESC
LIMIT 10;



-- Q5 — Customer review analysis

SELECT 
  ROUND(CAST(AVG(review_score) AS numeric), 2) AS avg_review_score,

  COUNT(*) AS total_reviews,

  SUM(
    CASE 
      WHEN review_score >= 4 THEN 1 
      ELSE 0 
    END
  ) AS positive_reviews,

  ROUND(
    CAST(
      SUM(
        CASE 
          WHEN review_score >= 4 THEN 1 
          ELSE 0 
        END
      ) * 100.0 / COUNT(*)
      AS numeric
    ),
    1
  ) AS positive_pct

FROM olist_order_reviews_dataset;



-- Q6 — Average delivery time by state
SELECT 
  c.customer_state,

  COUNT(*) AS total_orders,

  ROUND(
    CAST(
      AVG(
        EXTRACT(
          DAY FROM (
            o.order_delivered_customer_date::timestamp - 
            o.order_purchase_timestamp::timestamp
          )
        )
      ) AS numeric
    ),
    1
  ) AS avg_delivery_days

FROM olist_orders_dataset o

JOIN olist_customers_dataset c 
  ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- Q7 — Seller ranking by review score

SELECT 
  oi.seller_id,

  COUNT(r.review_id) AS review_count,

  ROUND(CAST(AVG(r.review_score) AS numeric), 2) AS avg_score,

  ROUND(CAST(SUM(oi.price) AS numeric), 2) AS total_revenue

FROM olist_order_items_dataset oi

JOIN olist_order_reviews_dataset r 
  ON oi.order_id = r.order_id

GROUP BY oi.seller_id

HAVING COUNT(r.review_id) >= 10

ORDER BY avg_score DESC
LIMIT 20;



-- Q8 — On-time delivery rate

SELECT 
  COUNT(*) AS delivered_orders,

  SUM(
    CASE 
      WHEN order_delivered_customer_date <= order_estimated_delivery_date 
      THEN 1 
      ELSE 0 
    END
  ) AS on_time_orders,

  ROUND(
    CAST(
      AVG(
        CASE 
          WHEN order_delivered_customer_date <= order_estimated_delivery_date 
          THEN 1.0 
          ELSE 0 
        END
      ) * 100
      AS numeric
    ),
    2
  ) AS on_time_rate_pct

FROM olist_orders_dataset

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;



-- Q9 — Monthly revenue trend

SELECT 
  strftime('%Y-%m', o.order_purchase_timestamp) AS month,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(CAST(SUM(op.payment_value) AS numeric), 2) AS monthly_revenue

FROM olist_orders_dataset o

JOIN olist_order_payments_dataset op 
  ON o.order_id = op.order_id

WHERE o.order_status = 'delivered'

GROUP BY month
ORDER BY month;



-- Q10 — Payment method breakdown

SELECT 
  payment_type,

  COUNT(DISTINCT order_id) AS total_orders,

  ROUND(CAST(AVG(payment_value) AS numeric), 2) AS avg_order_value,

  ROUND(CAST(SUM(payment_value) AS numeric), 2) AS total_revenue,

  ROUND(CAST(AVG(payment_installments) AS numeric), 1) AS avg_installments

FROM olist_order_payments_dataset

GROUP BY payment_type
ORDER BY total_orders DESC;



-- Q11 — Top 5 states by revenue

SELECT 
  c.customer_state,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(CAST(SUM(op.payment_value) AS numeric), 2) AS total_revenue,

  ROUND(CAST(AVG(op.payment_value) AS numeric), 2) AS avg_order_value

FROM olist_orders_dataset o

JOIN olist_customers_dataset c 
  ON o.customer_id = c.customer_id

JOIN olist_order_payments_dataset op 
  ON o.order_id = op.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 5;