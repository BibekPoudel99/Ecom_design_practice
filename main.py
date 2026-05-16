from etl_pipeline.extract import extract_all
from etl_pipeline.transform import (
    build_dim_date, build_dim_payment_method, build_dim_coupon,
    build_dim_user, build_dim_seller, build_dim_product,
    build_fact_sales
)
from etl_pipeline.load import (
    load_dim_date_once, apply_scd2, upsert, load_fact_sales
)

def run_pipeline():
    print("\n" + "="*50)
    print("PIPELINE STARTED")
    print("="*50)

    # EXTRACT
    print("\n--- EXTRACT ---")
    raw = extract_all()

    # TRANSFORM + LOAD dimensions
    print("\n--- LOAD DIMS ---")

    load_dim_date_once(build_dim_date())

    pm_df = build_dim_payment_method(raw.get("payments", __import__('pandas').DataFrame()))
    if not pm_df.empty:
        upsert(pm_df, "dwh.dim_payment_method", "payment_method")

    coupon_df = build_dim_coupon(raw.get("coupons", __import__('pandas').DataFrame()))
    if not coupon_df.empty:
        apply_scd2(coupon_df, "dim_coupon", "coupon_id", "coupon_key")

    user_df = build_dim_user(
        raw.get("users",         __import__('pandas').DataFrame()),
        raw.get("user_addresses",__import__('pandas').DataFrame())
    )
    apply_scd2(user_df, "dim_user", "user_id", "user_key")

    seller_df = build_dim_seller(raw.get("sellers", __import__('pandas').DataFrame()))
    apply_scd2(seller_df, "dim_seller", "seller_id", "seller_key")

    product_df = build_dim_product(
        raw.get("products",   __import__('pandas').DataFrame()),
        raw.get("product_variants", __import__('pandas').DataFrame()),
        raw.get("categories", __import__('pandas').DataFrame())
    )
    apply_scd2(product_df, "dim_product", "product_id", "product_key")

    # LOAD FACTS
    print("\n--- LOAD FACTS ---")

    from sqlalchemy import create_engine, text
    from config.config import OLAP_URL
    eng = create_engine(OLAP_URL)

    def fetch_dim(table, key_col, val_col):
        with eng.connect() as c:
            import pandas as pd
            return pd.read_sql(
                f"SELECT {key_col}, {val_col} FROM dwh.{table} WHERE is_current = TRUE",
                c
            ) if "is_current" in ["is_current"] else pd.read_sql(
                f"SELECT * FROM dwh.{table}", c
            )

    import pandas as pd
    dim_user    = pd.read_sql("SELECT * FROM dwh.dim_user    WHERE is_current=TRUE", eng)
    dim_seller  = pd.read_sql("SELECT * FROM dwh.dim_seller  WHERE is_current=TRUE", eng)
    dim_product = pd.read_sql("SELECT * FROM dwh.dim_product WHERE is_current=TRUE", eng)
    dim_pm      = pd.read_sql("SELECT * FROM dwh.dim_payment_method", eng)
    dim_coupon  = pd.read_sql("SELECT * FROM dwh.dim_coupon", eng)

    fact_df = build_fact_sales(
        raw.get("order_items", pd.DataFrame()),
        raw.get("orders",      pd.DataFrame()),
        raw.get("payments",    pd.DataFrame()),
        dim_user, dim_seller, dim_product, dim_pm, dim_coupon
    )
    load_fact_sales(fact_df)

    print("\n" + "="*50)
    print("PIPELINE COMPLETE")
    print("="*50)

if __name__ == "__main__":
    run_pipeline()