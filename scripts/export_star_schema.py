"""
Export Olist SQLite tables into Power BI–ready star-schema CSVs.
Source: ../../olist.db (same repo as this powerbi/ folder)
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd

BASE = Path(__file__).resolve().parent.parent  # .../olist_sql_analysis/powerbi
SQL_PROJECT = BASE.parent  # .../olist_sql_analysis
DB_PATH = SQL_PROJECT / "olist.db"
OUT = BASE / "data" / "model"
OUT.mkdir(parents=True, exist_ok=True)

conn = sqlite3.connect(DB_PATH)

# ---------- DimCustomer ----------
dim_customer = pd.read_sql_query(
    """
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM customers
    """,
    conn,
)

# ---------- DimProduct ----------
dim_product = pd.read_sql_query(
    """
    SELECT
        p.product_id,
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,
        p.product_category_name AS product_category_pt,
        p.product_name_lenght AS product_name_length,
        p.product_description_lenght AS product_description_length,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    FROM products p
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    """,
    conn,
)

# ---------- DimSeller ----------
dim_seller = pd.read_sql_query(
    """
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM sellers
    """,
    conn,
)

# ---------- DimOrder ----------
dim_order = pd.read_sql_query(
    """
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        CASE
            WHEN order_delivered_customer_date IS NULL
                OR order_purchase_timestamp IS NULL THEN NULL
            ELSE ROUND(
                julianday(order_delivered_customer_date)
                - julianday(order_purchase_timestamp),
                2
            )
        END AS delivery_days,
        CASE
            WHEN order_delivered_customer_date IS NULL
                OR order_purchase_timestamp IS NULL THEN 'Unknown'
            WHEN julianday(order_delivered_customer_date)
                - julianday(order_purchase_timestamp) < 7 THEN 'Less than 7 days'
            WHEN julianday(order_delivered_customer_date)
                - julianday(order_purchase_timestamp) < 14 THEN '7-14 days'
            WHEN julianday(order_delivered_customer_date)
                - julianday(order_purchase_timestamp) < 21 THEN '14-21 days'
            ELSE '+21 days'
        END AS delivery_bucket,
        CASE
            WHEN order_delivered_customer_date IS NULL
                OR order_estimated_delivery_date IS NULL THEN NULL
            WHEN julianday(order_delivered_customer_date)
                <= julianday(order_estimated_delivery_date) THEN 1
            ELSE 0
        END AS delivered_on_time_flag
    FROM orders
    """,
    conn,
)

# ---------- FactSales (order item grain) ----------
fact_sales = pd.read_sql_query(
    """
    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        o.customer_id,
        DATE(o.order_purchase_timestamp) AS order_date,
        o.order_status,
        oi.shipping_limit_date,
        oi.price AS product_revenue,
        oi.freight_value,
        ROUND(oi.price + oi.freight_value, 2) AS gross_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    """,
    conn,
)

# ---------- FactPayments ----------
fact_payments = pd.read_sql_query(
    """
    SELECT
        op.order_id,
        op.payment_sequential,
        op.payment_type,
        op.payment_installments,
        op.payment_value,
        DATE(o.order_purchase_timestamp) AS order_date,
        o.customer_id
    FROM order_payments op
    JOIN orders o ON op.order_id = o.order_id
    """,
    conn,
)

# ---------- FactReviews ----------
fact_reviews = pd.read_sql_query(
    """
    SELECT
        r.review_id,
        r.order_id,
        r.review_score,
        r.review_comment_title,
        r.review_comment_message,
        r.review_creation_date,
        r.review_answer_timestamp,
        DATE(o.order_purchase_timestamp) AS order_date,
        o.customer_id,
        CASE
            WHEN o.order_delivered_customer_date IS NULL
                OR o.order_purchase_timestamp IS NULL THEN 'Unknown'
            WHEN julianday(o.order_delivered_customer_date)
                - julianday(o.order_purchase_timestamp) < 7 THEN 'Less than 7 days'
            WHEN julianday(o.order_delivered_customer_date)
                - julianday(o.order_purchase_timestamp) < 14 THEN '7-14 days'
            WHEN julianday(o.order_delivered_customer_date)
                - julianday(o.order_purchase_timestamp) < 21 THEN '14-21 days'
            ELSE '+21 days'
        END AS delivery_bucket
    FROM order_reviews r
    JOIN orders o ON r.order_id = o.order_id
    """,
    conn,
)

# ---------- DimDate (from sales + payments + reviews dates) ----------
all_dates = pd.concat(
    [
        fact_sales[["order_date"]],
        fact_payments[["order_date"]],
        fact_reviews[["order_date"]],
    ],
    ignore_index=True,
)
all_dates = all_dates.dropna().drop_duplicates()
all_dates["order_date"] = pd.to_datetime(all_dates["order_date"])
date_min = all_dates["order_date"].min()
date_max = all_dates["order_date"].max()
dim_date = pd.DataFrame({"Date": pd.date_range(date_min, date_max, freq="D")})
dim_date["DateKey"] = dim_date["Date"].dt.strftime("%Y%m%d").astype(int)
dim_date["Year"] = dim_date["Date"].dt.year
dim_date["Quarter"] = dim_date["Date"].dt.quarter
dim_date["Month"] = dim_date["Date"].dt.month
dim_date["MonthName"] = dim_date["Date"].dt.strftime("%b")
dim_date["YearMonth"] = dim_date["Date"].dt.strftime("%Y-%m")
dim_date["Weekday"] = dim_date["Date"].dt.day_name()
dim_date["WeekdayNum"] = dim_date["Date"].dt.weekday + 1
dim_date["IsWeekend"] = dim_date["WeekdayNum"].isin([6, 7]).astype(int)

# Normalize date keys on facts for easy relationships
for df in (fact_sales, fact_payments, fact_reviews):
    df["order_date"] = pd.to_datetime(df["order_date"]).dt.strftime("%Y-%m-%d")

dim_date["Date"] = dim_date["Date"].dt.strftime("%Y-%m-%d")

exports = {
    "DimCustomer.csv": dim_customer,
    "DimProduct.csv": dim_product,
    "DimSeller.csv": dim_seller,
    "DimOrder.csv": dim_order,
    "DimDate.csv": dim_date,
    "FactSales.csv": fact_sales,
    "FactPayments.csv": fact_payments,
    "FactReviews.csv": fact_reviews,
}

for name, df in exports.items():
    path = OUT / name
    df.to_csv(path, index=False)
    print(f"{name}: {len(df):,} rows → {path}")

conn.close()
print("\nStar schema export complete.")
