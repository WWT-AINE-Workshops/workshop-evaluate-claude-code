"""Create the local database with sample data. Run with: python -m app.seed"""
from app.auth import hash_password
from app.db import connect, init_db


def seed() -> None:
    init_db()
    with connect() as conn:
        conn.executemany(
            "INSERT OR IGNORE INTO users (id, username, password_hash, role) VALUES (?, ?, ?, ?)",
            [
                (1, "acme-logistics", hash_password("change-me-1"), "customer"),
                (2, "bluebird-retail", hash_password("change-me-2"), "customer"),
                (3, "support-lead", hash_password("change-me-3"), "admin"),
            ],
        )
        conn.executemany(
            "INSERT OR IGNORE INTO carriers (id, name, code, on_time_rate) VALUES (?, ?, ?, ?)",
            [(1, "Coastline Express", "CLX", 0.94), (2, "Prairie Parcel", "PRP", 0.88)],
        )
        conn.executemany(
            "INSERT OR IGNORE INTO shipments (id, reference, customer_id, carrier_id, recipient_name, "
            "destination, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [
                (1, "NW-1001", 1, 1, "Dana Ortiz", "Denver, CO", "in_transit"),
                (2, "NW-1002", 1, 2, "Sam Lee", "Omaha, NE", "delivered"),
                (3, "NW-2001", 2, 1, "Priya Shah", "Tampa, FL", "created"),
            ],
        )


if __name__ == "__main__":
    seed()
