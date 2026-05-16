import pandas as pd
from datetime import date, timedelta

def build_dim_date(start_year=2020, end_year=2030) -> pd.DataFrame:
    """Generate date dimension. Run once."""
    rows = []
    d = date(start_year, 1, 1)
    end = date(end_year, 12, 31)
    while d <= end:
        rows.append({
            "date_key":    int(d.strftime("%Y%m%d")),
            "full_date":   d,
            "day":         d.day,
            "month":       d.month,
            "month_name":  d.strftime("%B"),
            "quarter":     (d.month - 1) // 3 + 1,
            "year":        d.year,
            "day_of_week": d.isoweekday(),
            "day_name":    d.strftime("%A"),
            "is_weekend":  d.isoweekday() >= 6,
        })
        d += timedelta(days=1)
    return pd.DataFrame(rows)

def build_dim_payment_method(payments: pd.DataFrame) -> pd.DataFrame:
    if payments.empty:
        return pd.DataFrame(columns=["payment_method"])
    return (payments[["payment_method"]]
                .drop_duplicates()
                .reset_index(drop=True))

def build_dim_coupon(coupons: pd.DataFrame) -> pd.DataFrame:
    if coupons.empty:
        return pd.DataFrame()
    return coupons[["coupon_id", "code", "discount_type", "discount_value"]].copy()

def build_dim_user(users: pd.DataFrame, addresses: pd.DataFrame) -> pd.DataFrame:
    if users.empty:
        return pd.DataFrame()

    df = users[["user_id", "first_name", "last_name", "email", "phone"]].copy()
    df["full_name"] = df["first_name"] + " " + df["last_name"]

    if not addresses.empty:
        primary = (addresses[addresses["is_default"] == True]
                       [["user_id", "city", "country"]]
                       .drop_duplicates("user_id"))
        df = df.merge(primary, on="user_id", how="left")
    else:
        df["city"]    = None
        df["country"] = None

    return df[["user_id", "full_name", "email", "phone", "city", "country"]]

def build_dim_seller(sellers: pd.DataFrame) -> pd.DataFrame:
    if sellers.empty:
        return pd.DataFrame()
    return sellers[[
        "seller_id", "store_name", "email",
        "commission_rate", "rating"
    ]].copy()

def build_dim_product(
    products:   pd.DataFrame,
    variants:   pd.DataFrame,
    categories: pd.DataFrame
) -> pd.DataFrame:
    if products.empty:
        return pd.DataFrame()

    cat_map = {}
    if not categories.empty:
        cat_map = categories.set_index("category_id")["name"].to_dict()

    df = products[["product_id", "name", "category_id", "seller_id", "price"]].copy()
    df = df.rename(columns={"name": "product_name", "price": "base_price"})
    df["category"] = df["category_id"].map(cat_map)

    if not variants.empty:
        var = variants[["variant_id", "product_id", "sku"]].copy()
        df = df.merge(var, on="product_id", how="left")
    else:
        df["variant_id"] = None
        df["sku"]        = None

    return df[[
        "product_id", "variant_id", "product_name",
        "category", "seller_id", "sku", "base_price"
    ]]

def build_fact_sales(
    order_items:    pd.DataFrame,
    orders:         pd.DataFrame,
    payments:       pd.DataFrame,
    dim_user:       pd.DataFrame,
    dim_seller:     pd.DataFrame,
    dim_product:    pd.DataFrame,
    dim_pay_method: pd.DataFrame,
    dim_coupon:     pd.DataFrame,
) -> pd.DataFrame:

    if order_items.empty or orders.empty:
        return pd.DataFrame()

    # Join order_items → orders
    df = order_items.merge(
        orders[["order_id", "user_id", "coupon_id",
                "shipping_cost", "created_at"]],
        on="order_id", how="left"
    )

    # date_key from order created_at
    df["date_key"] = pd.to_datetime(df["created_at"]).dt.strftime("%Y%m%d").astype(int)

    # Join payments for payment method
    if not payments.empty:
        pay = payments[["order_id", "payment_method"]].drop_duplicates("order_id")
        df  = df.merge(pay, on="order_id", how="left")
    else:
        df["payment_method"] = None

    # Lookup keys from dims
    if not dim_user.empty:
        user_map = dim_user.set_index("user_id")["user_key"].to_dict()
        df["user_key"] = df["user_id"].map(user_map)

    if not dim_seller.empty:
        seller_map = dim_seller.set_index("seller_id")["seller_key"].to_dict()
        df["seller_key"] = df["seller_id"].map(seller_map) if "seller_id" in df else None

    if not dim_product.empty:
        prod_map = dim_product.set_index("product_id")["product_key"].to_dict()
        df["product_key"] = df["product_id"].map(prod_map)

    if not dim_pay_method.empty:
        pm_map = dim_pay_method.set_index("payment_method")["payment_method_key"].to_dict()
        df["payment_method_key"] = df["payment_method"].map(pm_map)

    if not dim_coupon.empty:
        c_map = dim_coupon.set_index("coupon_id")["coupon_key"].to_dict()
        df["coupon_key"] = df["coupon_id"].map(c_map)

    # Measures
    df["gross_revenue"]     = df["quantity"] * df["unit_price"]
    df["discount_amount"]   = df.get("discount_amount", 0)
    df["net_revenue"]       = df["gross_revenue"] - df["discount_amount"].fillna(0)
    df["commission_rate"]   = df.get("commission_rate", 0)
    df["commission_amount"] = df["net_revenue"] * (df["commission_rate"].fillna(0) / 100)
    df["seller_earnings"]   = df["net_revenue"] - df["commission_amount"]
    df["shipping_cost"]     = df.get("shipping_cost", 0)

    return df[[
        "order_item_id", "order_id", "date_key",
        "user_key", "seller_key", "product_key",
        "payment_method_key", "coupon_key",
        "quantity", "unit_price",
        "gross_revenue", "discount_amount", "net_revenue",
        "commission_rate", "commission_amount",
        "seller_earnings", "shipping_cost"
    ]]