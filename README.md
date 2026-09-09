# Olist E-Commerce SQL Analysis

SQL-based analysis of the **Olist Brazilian E-Commerce Public Dataset** using **SQLite** to explore sales performance, customer behavior, payment preferences, product categories, geographic demand, and delivery performance.

This project focuses on writing clean and practical SQL queries, validating relational data quality, and translating raw e-commerce data into business-oriented insights.

---

## Project Overview

The goal of this project is to analyze an e-commerce dataset containing nearly **100,000 orders** and over **112,000 order items**.

The analysis covers:

* Sales and order trends
* Product revenue
* Product category performance
* Sales volume
* Average Order Value (AOV)
* Geographic demand
* Payment method usage
* Customer review scores
* Delivery performance
* Relationship between delivery time and customer satisfaction

The project also includes database validation checks to ensure the reliability and consistency of the data before performing business analysis.

---

## Dataset

The project uses the **Olist Brazilian E-Commerce Public Dataset**, which contains information about orders, customers, products, sellers, payments, reviews, and geographic data.

The database contains the following tables:

| Table                |      Rows |
| -------------------- | --------: |
| customers            |    99,441 |
| products             |    32,951 |
| sellers              |     3,095 |
| orders               |    99,441 |
| order_items          |   112,650 |
| order_payments       |   103,886 |
| order_reviews        |    99,224 |
| geolocation          | 1,000,163 |
| category_translation |        71 |

The raw CSV files and SQLite database are excluded from the Git repository through `.gitignore`.

---

## Project Structure

```text
olist_sql_analysis/
│
├── data/
│   └── Raw dataset files
│
├── scripts/
│   └── load_data.py
│
├── sql/
│   ├── analysis.sql
│   └── schema.sql
│
├── README.md
├── requirements.txt
└── .gitignore
```

### Main Files

**`scripts/load_data.py`**
Loads the CSV files into the SQLite database.

**`sql/schema.sql`**
Defines the database schema and table structures.

**`sql/analysis.sql`**
Contains data validation queries and all business analysis queries.

---

## Data Validation

Before performing business analysis, the database was validated using SQL.

### Primary Key Validation

The following tables were checked for duplicate primary keys:

* customers
* products
* sellers
* orders

All primary keys were unique.

| Table     | Total Rows | Unique IDs |
| --------- | ---------: | ---------: |
| customers |     99,441 |     99,441 |
| products  |     32,951 |     32,951 |
| sellers   |      3,095 |      3,095 |
| orders    |     99,441 |     99,441 |

### Composite Key Validation

Composite keys were checked for duplicate combinations in:

* `order_items`
* `order_payments`
* `order_reviews`

Result:

| Table          | Duplicate Keys |
| -------------- | -------------: |
| order_items    |              0 |
| order_payments |              0 |
| order_reviews  |              0 |

### Foreign Key Validation

Relationships between the main tables were also checked for orphan records.

All tested relationships returned **0 orphan records**:

* orders → customers
* order_items → orders
* order_items → products
* order_items → sellers
* order_payments → orders
* order_reviews → orders

### Data Quality Checks

The following conditions were tested:

* Missing customer IDs
* Missing order status
* Missing purchase timestamps
* Negative product prices
* Negative freight values
* Negative payment values
* Invalid payment installments
* Invalid review scores
* Negative product weight
* Negative product dimensions

All checks returned zero issues except for **2 payment records with zero installments**.

These records were retained and documented rather than removed from the dataset.

---

# Business Analysis

## 1. Monthly Order Trends

### Business Question

**How has the number of orders changed over time?**

The analysis groups orders by purchase month to identify overall growth and seasonal patterns.

### Key Insight

Order volume increased significantly throughout 2017 and remained at a high level during most of 2018.

The highest number of orders occurred in **November 2017**, with:

**7,544 orders**

The unusually low order counts at the beginning and end of the dataset are treated as dataset coverage boundaries rather than evidence of a business decline.

---

## 2. Monthly Product Revenue

### Business Question

**How much product revenue is generated each month?**

Product revenue is calculated using the `price` field from `order_items`.

Freight charges are excluded so that the metric represents **product sales revenue** rather than total order value including shipping.

### Key Insight

Monthly product revenue increased substantially during 2017 and remained close to or above **850K** during most months of 2018.

The highest monthly product revenue occurred in:

**November 2017 — 1,010,271.37**

This coincides with the highest monthly order volume, indicating a particularly strong sales period.

---

## 3. Revenue by Product Category

### Business Question

**Which product categories generate the most revenue?**

Product categories were translated into English using the `category_translation` table where available.

Products without a category were retained and grouped under **`Unknown`** rather than being removed from the analysis.

### Top Revenue Categories

| Category              | Product Revenue |
| --------------------- | --------------: |
| health_beauty         |    1,258,681.34 |
| watches_gifts         |    1,205,005.68 |
| bed_bath_table        |    1,036,988.68 |
| sports_leisure        |      988,048.97 |
| computers_accessories |      911,954.32 |

### Key Insight

**Health & Beauty** generated the highest product revenue at approximately **1.26M**, followed by **Watches & Gifts** at approximately **1.21M**.

These categories represent the strongest revenue contributors in the dataset.

---

## 4. Sales Volume by Product Category

### Business Question

**Which product categories have the highest number of items sold?**

Sales volume is measured by counting rows in `order_items`, where each row represents an ordered item.

### Top Categories by Sales Volume

| Category              | Items Sold |
| --------------------- | ---------: |
| bed_bath_table        |     11,115 |
| health_beauty         |      9,670 |
| sports_leisure        |      8,641 |
| furniture_decor       |      8,334 |
| computers_accessories |      7,827 |

### Key Insight

**Bed & Bath Table** has the highest sales volume with **11,115 items sold**.

Interestingly, **Health & Beauty** ranks first in revenue but second in item volume, showing that revenue performance and sales volume do not necessarily produce the same ranking.

---

## 5. Average Order Value

### Business Question

**What is the average product revenue generated per order?**

Average Order Value (AOV) was calculated by dividing total product revenue by the number of unique orders.

### Result

**Average Order Value: 137.75 BRL**

This metric uses product prices only and excludes freight charges.

### Key Insight

On average, each order generated approximately **137.75 BRL in product revenue**.

---

## 6. Orders by Customer State

### Business Question

**Which states have the highest number of orders?**

Customer location was used to analyze geographic demand across Brazilian states.

### Top States

| State | Orders |
| ----- | -----: |
| SP    | 41,746 |
| RJ    | 12,852 |
| MG    | 11,635 |
| RS    |  5,466 |
| PR    |  5,045 |
| SC    |  3,637 |
| BA    |  3,380 |

### Key Insight

**São Paulo (SP)** is by far the largest market in the dataset, with **41,746 orders**.

It accounts for substantially more orders than the next largest markets, Rio de Janeiro (RJ) and Minas Gerais (MG).

This indicates a strong concentration of customer demand in Brazil's southeastern region.

---

## 7. Payment Method Usage

### Business Question

**Which payment methods are used most frequently?**

Payment transactions were grouped by payment type.

### Results

| Payment Method | Transactions |
| -------------- | -----------: |
| credit_card    |       76,795 |
| boleto         |       19,784 |
| voucher        |        5,775 |
| debit_card     |        1,529 |
| not_defined    |            3 |

### Key Insight

**Credit card** is the dominant payment method, accounting for approximately **74% of payment records**.

Boleto is the second most frequently used payment method.

---

## 8. Average Review Score by Payment Method

### Business Question

**What is the average customer review score for each payment method?**

Payment methods were compared against customer review scores to explore whether customer satisfaction differs across payment types.

### Results

| Payment Method | Average Review Score |
| -------------- | -------------------: |
| debit_card     |                 4.17 |
| credit_card    |                 4.09 |
| boleto         |                 4.09 |
| voucher        |                 4.00 |
| not_defined    |                 1.67 |

### Key Insight

Customers using **debit cards** had the highest average review score at **4.17**.

The `not_defined` category has an average score of 1.67, but it contains only **3 payment records**, so this result should not be considered statistically representative.

---

## 9. Average Delivery Time

### Business Question

**How long does it take to deliver an order after purchase?**

Delivery time was calculated as the difference between:

* `order_purchase_timestamp`
* `order_delivered_customer_date`

SQLite's `julianday()` function was used to calculate the difference in days.

### Result

**Average Delivery Time: 12.56 days**

### Key Insight

Orders took an average of approximately **12.56 days** to reach customers after purchase.

This metric provides a baseline for evaluating delivery performance and potential delivery delays.

---

## 10. Delivery Time and Customer Satisfaction

### Business Question

**Does delivery delay affect customer review scores?**

Delivery times were divided into four groups and compared with average customer review scores.

The analysis is intended to identify an **association** between delivery time and customer satisfaction, not to establish causation.

### Results

| Delivery Time    | Average Review Score |
| ---------------- | -------------------: |
| Less than 7 days |                 4.42 |
| 7–14 days        |                 4.31 |
| 14–21 days       |                 4.14 |
| +21 days         |                 3.12 |

### Key Insight

The results show a clear negative relationship between delivery time and review score.

As delivery time increases, the average customer review score decreases:

* Less than 7 days → **4.42**
* 7–14 days → **4.31**
* 14–21 days → **4.14**
* More than 21 days → **3.12**

This suggests that longer delivery times are associated with lower customer satisfaction.

---

# Key Business Insights

The analysis produced several important findings:

### Sales Growth

Order volume and product revenue increased substantially from 2017 into 2018, with **November 2017** being the strongest month for both orders and product revenue.

### Category Performance

**Health & Beauty** generated the highest product revenue, while **Bed & Bath Table** had the highest number of items sold.

This demonstrates that the categories with the highest sales volume are not necessarily the same categories generating the highest revenue.

### Geographic Concentration

Customer demand is highly concentrated in **São Paulo**, followed by **Rio de Janeiro** and **Minas Gerais**.

### Payment Preferences

Credit cards are the dominant payment method, representing approximately **74% of payment records**.

### Delivery Performance

The average delivery time was **12.56 days**.

More importantly, the analysis indicates that longer delivery times are associated with lower review scores, with average satisfaction falling from **4.42** for deliveries under 7 days to **3.12** for deliveries taking more than 21 days.

---

# SQL Skills Demonstrated

This project demonstrates practical SQL skills including:

* `SELECT`
* `WHERE`
* `GROUP BY`
* `ORDER BY`
* `COUNT`
* `COUNT(DISTINCT ...)`
* `SUM`
* `AVG`
* `ROUND`
* `CASE`
* `COALESCE`
* `JOIN`
* `LEFT JOIN`
* `UNION ALL`
* Subqueries
* `HAVING`
* Date/time analysis with `strftime()`
* Date calculations with `julianday()`
* Primary key validation
* Composite key validation
* Foreign key integrity checks
* Data quality validation

---

# Tools & Technologies

* **SQLite**
* **SQL**
* **Python**
* **Pandas**
* **Git**
* **GitHub**
* **VS Code**

Python was used primarily for loading the source CSV files into SQLite, while SQL was used for database validation and business analysis.

---

# Project Focus

This project was designed to demonstrate the ability to move from:

**Raw Data → Database → Data Validation → SQL Analysis → Business Insights**

rather than simply writing isolated SQL queries.

The analysis emphasizes data integrity, clear metric definitions, appropriate joins, and business-oriented interpretation of SQL results.

---

## Author

**Kiana Bagheri**

Mechanical Engineering graduate transitioning into **Data Analysis**, with a focus on SQL, Python, data cleaning, and business-oriented data analysis.
