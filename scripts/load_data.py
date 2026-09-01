import sqlite3
import pandas as pd
from pathlib import Path

base_dir = Path(__file__).resolve().parent.parent
db_path = base_dir / "olist.db"

conn = sqlite3.connect(db_path)

# =========================
# 1. Customers
# =========================

customers_path = base_dir / "data" / "olist_customers_dataset.csv"
customers = pd.read_csv(customers_path)

customers.to_sql(
    "customers",
    conn ,
    if_exists="append",
    index=False
)

# =========================
# 2. Orders
# =========================

orders_path = base_dir / "data" / "olist_orders_dataset.csv"
orders = pd.read_csv(orders_path)

orders.to_sql(
    "orders",
    conn ,
    if_exists="append",
    index=False
)

conn.close()

print("succesfully added")

