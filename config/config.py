import os
from dotenv import load_dotenv

load_dotenv()

PG = {
    "host":     os.getenv("PG_HOST", "localhost"),
    "port":     os.getenv("PG_PORT", "5432"),
    "dbname":   os.getenv("PG_DBNAME", "e_marketplace"),
    "user":     os.getenv("PG_USER", "postgres"),
    "password": os.getenv("PG_PASS", ""),
}

OLTP_SCHEMA = "public"
DWH_SCHEMA  = "dwh"

OLAP_URL = (
    f"postgresql+psycopg2://{PG['user']}:{PG['password']}"
    f"@{PG['host']}:{PG['port']}/{PG['dbname']}"
)