from sqlalchemy import text
from datetime import datetime, timezone

def get_watermark(conn, table_name: str) -> datetime:
    result = conn.execute(
        text("SELECT last_extracted_at FROM dwh.etl_watermark WHERE table_name = :t"),
        {"t": table_name}
    ).fetchone()
    if result:
        return result[0]
    return datetime(2000, 1, 1, tzinfo=timezone.utc)

def set_watermark(conn, table_name: str):
    conn.execute(text("""
        INSERT INTO dwh.etl_watermark (table_name, last_extracted_at)
        VALUES (:t, now())
        ON CONFLICT (table_name)
        DO UPDATE SET last_extracted_at = now()
    """), {"t": table_name})