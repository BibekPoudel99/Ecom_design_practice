import pandas as pd
from sqlalchemy import text, create_engine
from config.config import OLAP_URL
from etl_pipeline.watermark import get_watermark, set_watermark

engine = create_engine(OLAP_URL)

TABLES = {
    "orders":                   "updated_at",
    "order_items":              "created_at",
    "users":                    "updated_at",
    "products":                 "updated_at",
    "product_variants":         "created_at",
    "sellers":                  "created_at",
    "inventory":                "last_updated",
    "payments":                 "updated_at",
    "shipments":                "created_at",
    "reviews":                  "created_at",
    "coupons":                  "created_at",
    "coupon_usage":             "used_at",
    "order_status_history":     "changed_at",
    "user_addresses":           "created_at",
    "categories":               None,
    "attributes":               None,
    "warehouses":               None,
    "variant_attribute_values": None,
}

def extract_all() -> dict:
    extracted = {}
    with engine.connect() as conn:
        for table, ts_col in TABLES.items():
            try:
                if ts_col is None:
                    df = pd.read_sql(
                        f"SELECT * FROM public.{table}",
                        conn
                    )
                else:
                    wm = get_watermark(conn, table)
                    df = pd.read_sql(
                        text(f"""
                            SELECT * FROM public.{table}
                            WHERE {ts_col} > :wm
                            ORDER BY {ts_col} ASC
                        """),
                        conn,
                        params={"wm": wm}
                    )

                if table == "payments" and "method" in df.columns:
                    df = df.rename(columns={"method": "payment_method"})

                extracted[table] = df

                if df.empty:
                    print(f"[EXTRACT] {table}: no new data")
                else:
                    print(f"[EXTRACT] {table}: {len(df)} rows")

                # Update watermark even for full-extract tables
                set_watermark(conn, table)
            except Exception as e:
                print(f"[EXTRACT] {table}: FAILED — {e}")

        conn.commit()
    return extracted