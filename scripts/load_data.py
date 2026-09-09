import sqlite3
from pathlib import Path
import pandas as pd

# =========================
# Paths
# =========================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
DB_PATH = BASE_DIR / "olist.db"

# =========================
# Database connection
# =========================

conn = sqlite3.connect(DB_PATH)

# =========================
# Load data
# =========================

tables = {
    "customers": "olist_customers_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

for table_name, file_name in tables.items():
    file_path = DATA_DIR / file_name

    print(f"Loading {file_name}...")

    df = pd.read_csv(file_path)

    df.to_sql(
        table_name,
        conn,
        if_exists="append",
        index=False
    )

    print(f"{table_name}: {len(df):,} rows loaded.")


# =========================
# Close connection
# =========================

conn.close()

print("\nAll data loaded successfully.")