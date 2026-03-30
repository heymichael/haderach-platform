#!/usr/bin/env python3
"""
DEPRECATED — user seeding has moved to the agent repo's Postgres-based script:

    cd ../agent
    source .venv/bin/activate
    DATABASE_URL="postgresql://..." python scripts/seed_users.py

This Firestore version is retained only for rollback reference. Do not use
for new seeding operations.
"""

raise SystemExit(
    "This script is deprecated. Use agent/scripts/seed_users.py (Postgres) instead."
)
