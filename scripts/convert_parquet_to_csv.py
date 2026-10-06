import duckdb

files = [
    "plans",
    "organizations",
    "users",
    "subscriptions",
    "invoices",
    "usage_events"
]

for file in files:
    duckdb.execute(f"""
        COPY (
            SELECT *
            FROM read_parquet('{file}.parquet')
        )
        TO '{file}.csv'
        (HEADER, DELIMITER ',');
    """)

    count = duckdb.execute(
        f"SELECT COUNT(*) FROM read_parquet('{file}.parquet')"
    ).fetchone()[0]

    print(f"{file}.csv created successfully - {count:,} rows")
    