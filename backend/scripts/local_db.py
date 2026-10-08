"""Runs PostgreSQL without Docker, from Python (pgserver), with the data in backend/.pgdata.

    uv run --with pgserver python scripts/local_db.py

Prints the DATABASE_URL to put in .env. The server keeps running in the background;
run this again after a restart of the computer. Stop it with:

    uv run --with pgserver python scripts/local_db.py --stop
"""

import sys
from pathlib import Path

import pgserver

DATA = Path(__file__).resolve().parent.parent / ".pgdata"

if "--stop" in sys.argv:
    pgserver.get_server(DATA, cleanup_mode="stop").cleanup()
    print("PostgreSQL stopped")
    sys.exit()

# cleanup_mode=None: keep running after this script exits
server = pgserver.get_server(DATA, cleanup_mode=None)
if "uzsl" not in server.psql("SELECT datname FROM pg_database;"):
    server.psql("CREATE DATABASE uzsl;")
socket_dir = server.get_uri().split("host=", 1)[1]
print(f"DATABASE_URL=postgresql+asyncpg://postgres@/uzsl?host={socket_dir}")
