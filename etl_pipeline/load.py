import pandas as pd
from sqlalchemy import create_engine, text
from datetime import datetime, timezone
from config.config import OLAP_URL

engine = create_engine(OLAP_URL)

def upsert(df: pd.DataFrame, table: str, conflict_col: str):
    """Insert with ON CONFLICT DO NOTHING for idempotency."""
    if df.empty:
        print(f"[LOAD] {table}: nothing to load")
        return
    df.to_sql(
        name=table.split(".")[-1],
        schema=table.split(".")[0],
        con=engine,
        if_exists="append",
        index=False,
        method="multi"
    )
    print(f"[LOAD] {table}: {len(df)} rows")

def load_dim_date_once(df: pd.DataFrame):
    with engine.connect() as conn:
        count = conn.execute(
            text("SELECT COUNT(*) FROM dwh.dim_date")
        ).scalar()
        if count == 0:
            df.to_sql("dim_date", engine, schema="dwh",
                      if_exists="append", index=False)
            print(f"[LOAD] dim_date: {len(df)} rows seeded")
        else:
            print("[LOAD] dim_date: already seeded, skipped")
        conn.commit()

def apply_scd2(
    df: pd.DataFrame,
    table: str,
    natural_key: str,
    surrogate_key: str
):
    """Minimal SCD2: expire old, insert new."""
    if df.empty:
        print(f"[LOAD] {table}: nothing to load")
        return

    now = datetime.now(timezone.utc)

    with engine.connect() as conn:
        for _, row in df.iterrows():
            nk_val = row[natural_key]

            # Expire current record if it exists
            conn.execute(text(f"""
                UPDATE dwh.{table}
                SET effective_to = :now,
                    is_current   = FALSE
                WHERE {natural_key} = :nk
                AND   is_current   = TRUE
            """), {"now": now, "nk": nk_val})

            # Insert new current record
            row_dict = row.to_dict()
            row_dict["effective_from"] = now
            row_dict["effective_to"]   = None
            row_dict["is_current"]     = True
            row_dict.pop(surrogate_key, None)

            cols   = ", ".join(row_dict.keys())
            vals   = ", ".join([f":{k}" for k in row_dict.keys()])
            conn.execute(
                text(f"INSERT INTO dwh.{table} ({cols}) VALUES ({vals})"),
                row_dict
            )

        conn.commit()
    print(f"[LOAD] {table}: {len(df)} rows upserted (SCD2)")

def load_fact_sales(df: pd.DataFrame):
    if df.empty:
        print("[LOAD] fact_sales: nothing to load")
        return
    with engine.connect() as conn:
        for _, row in df.iterrows():
            conn.execute(text("""
                INSERT INTO dwh.fact_sales (
                    order_item_id, order_id, date_key,
                    user_key, seller_key, product_key,
                    payment_method_key, coupon_key,
                    quantity, unit_price,
                    gross_revenue, discount_amount, net_revenue,
                    commission_rate, commission_amount,
                    seller_earnings, shipping_cost
                ) VALUES (
                    :order_item_id, :order_id, :date_key,
                    :user_key, :seller_key, :product_key,
                    :payment_method_key, :coupon_key,
                    :quantity, :unit_price,
                    :gross_revenue, :discount_amount, :net_revenue,
                    :commission_rate, :commission_amount,
                    :seller_earnings, :shipping_cost
                )
                ON CONFLICT (order_item_id) DO NOTHING
            """), row.to_dict())
        conn.commit()
    print(f"[LOAD] fact_sales: {len(df)} rows")