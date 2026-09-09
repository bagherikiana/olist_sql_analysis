-- =========================
-- Row Count Validation
-- =========================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'category_translation', COUNT(*)
FROM category_translation;

-- =========================
-- Primary Key Validation
-- =========================

SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids
FROM customers

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT
    'sellers',
    COUNT(*),
    COUNT(DISTINCT seller_id)
FROM sellers

UNION ALL

SELECT
    'orders',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM orders;

-- =========================
-- Composite Primary Key Validation
-- =========================

SELECT
    'order_items' AS table_name,
    COUNT(*) AS duplicate_keys
FROM (
    SELECT order_id, order_item_id
    FROM order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'order_payments',
    COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'order_reviews',
    COUNT(*)
FROM (
    SELECT review_id, order_id
    FROM order_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
);

-- =========================
-- Foreign Key Validation
-- =========================

-- orders -> customers
SELECT
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

-- order_items -> orders
SELECT
    'order_items -> orders',
    COUNT(*)
FROM order_items oi
LEFT JOIN orders o 
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

-- order_items -> products
SELECT
    'order_items -> products',
    COUNT(*)
FROM order_items oi
LEFT JOIN products p  
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

-- order_items -> sellers
SELECT
    'order_items -> sellers',
    COUNT(*)
FROM order_items oi
LEFT JOIN sellers s  
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

-- order_payments -> orders
SELECT
    'order_payments -> orders',
    COUNT(*)
FROM order_payments op
LEFT JOIN orders o 
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

-- order_reviews -> orders
SELECT
    'order_reviews -> orders',
    COUNT(*)
FROM order_reviews r 
LEFT JOIN orders o 
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- =========================
-- Data Quality Validation
-- =========================

-- Orders: missing customer_id
SELECT
    'orders: NULL customer_id' AS check_name,
    COUNT(*) AS issue_count
FROM orders
WHERE customer_id IS NULL

UNION ALL

-- Orders: missing order_status
SELECT
    'orders: NULL order_status',
    COUNT(*)
FROM orders
WHERE order_status IS NULL

UNION ALL

-- Orders: missing purchase timestamp
SELECT
    'orders: NULL purchase timestamp',
    COUNT(*)
FROM orders
WHERE order_purchase_timestamp IS NULL

UNION ALL

-- Order Items: negative price
SELECT
    'order_items: negative price',
    COUNT(*)
FROM order_items
WHERE price < 0

UNION ALL

-- Order Items: negative freight value
SELECT
    'order_items: negative freight',
    COUNT(*)
FROM order_items
WHERE freight_value < 0

UNION ALL

-- Payments: negative payment value
SELECT
    'order_payments: negative payment value',
    COUNT(*)
FROM order_payments
WHERE payment_value < 0

UNION ALL

-- Payments: invalid installments
SELECT
    'order_payments: invalid installments',
    COUNT(*)
FROM order_payments
WHERE payment_installments <= 0

UNION ALL

-- Reviews: invalid review score
SELECT
    'order_reviews: invalid review score',
    COUNT(*)
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5

UNION ALL

-- Products: negative weight
SELECT
    'products: negative weight',
    COUNT(*)
FROM products
WHERE product_weight_g < 0

UNION ALL

-- Products: negative dimensions
SELECT
    'products: negative dimensions',
    COUNT(*)
FROM products
WHERE product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- data-quality issue
SELECT *
FROM order_payments
WHERE payment_installments <= 0;

-- =========================
-- Business Analysis
-- =========================

-- Question 1:
-- How has the number of orders changed over time?
-- This helps identify overall sales growth and seasonal patterns.

SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

-- Question 2:
-- How much revenue is generated each month?
-- This helps analyze the monthly revenue trend and identify high- and low-performing periods.

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Question 3:
-- Which product categories generate the most revenue?
-- This identifies the most valuable product categories based on item sales.

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY total_revenue DESC;

-- Question 4:
-- Which product categories have the highest number of items sold?
-- This identifies the categories with the highest sales volume.

SELECT
    COALESCE(
    ct.product_category_name_english,
    p.product_category_name,
    'Unknown'
) AS category,
    COUNT(*) AS items_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY items_sold DESC;

-- Question 5:
-- What is the average order value?
-- This measures how much customers spend on average per order.

SELECT
    ROUND(
    SUM(oi.price) /
    COUNT(DISTINCT oi.order_id),
    2
    )AS average_order_value
FROM order_items oi
JOIN orders o
    ON o.order_id = oi.order_id;

-- Question 6:
-- Which states have the highest number of orders?
-- This helps identify the geographic regions with the highest customer demand.

SELECT
    c.customer_state AS state,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- Question 7:
-- Which payment methods are used most frequently?
-- This helps understand customer payment preferences.

SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;


-- Question 8:
-- What is the average review score for each payment method?
-- This explores whether customer satisfaction differs across payment methods.

SELECT
    op.payment_type,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM order_payments op
JOIN order_reviews r
    ON op.order_id = r.order_id
GROUP BY op.payment_type
ORDER BY average_review_score DESC;


-- Question 9:
-- How long does it take to deliver an order after purchase?
-- This measures the average delivery time in days.

SELECT
    ROUND(
        AVG(
            julianday(order_delivered_customer_date)
            - julianday(order_purchase_timestamp)
        ),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- Question 10:
-- Does delivery delay affect customer review scores?
-- This explores the relationship between delivery performance and customer satisfaction.

SELECT
    CASE
        WHEN julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp) < 7
            THEN 'Less than 7 days'
        WHEN julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp) < 14
            THEN '7-14 days'
        WHEN julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp) < 21
            THEN '14-21 days'
        ELSE '+21 days'
    END AS delivery_time_group,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM orders o
    JOIN order_reviews r
     ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_time_group
ORDER BY
    CASE delivery_time_group
        WHEN 'Less than 7 days' THEN 1
        WHEN '7-14 days' THEN 2
        WHEN '14-21 days' THEN 3
        WHEN '+21 days' THEN 4
    END;