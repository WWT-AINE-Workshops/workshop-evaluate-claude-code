"""SQLite access helpers."""
import sqlite3
from contextlib import contextmanager

from app import config


@contextmanager
def connect():
    conn = sqlite3.connect(config.DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'customer'
);
CREATE TABLE IF NOT EXISTS carriers (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    on_time_rate REAL NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS shipments (
    id INTEGER PRIMARY KEY,
    reference TEXT UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES users(id),
    carrier_id INTEGER REFERENCES carriers(id),
    recipient_name TEXT NOT NULL,
    destination TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'created'
);
"""


def init_db():
    with connect() as conn:
        conn.executescript(SCHEMA)
