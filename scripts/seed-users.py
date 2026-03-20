#!/usr/bin/env python3
"""
Seed Firestore `users` collection with role assignments for RBAC.

Each document is keyed by normalized (lowercase, trimmed) email.
Documents contain a `roles` array and a `createdAt` ISO timestamp.

Prerequisites:
  pip install firebase-admin
  gcloud auth application-default login

Usage:
  python scripts/seed-users.py
"""

import firebase_admin
from datetime import datetime, timezone
from firebase_admin import credentials, firestore

PROJECT_ID = "haderach-ai"

USERS = {
    "michael@haderachi.ai": ["admin"],
    "michael@heretic.fund": ["admin"],
    "mariam@heretic.fund": ["admin"],
    "mariam@heretic.ventures": ["admin"],
    "alexmader@gmail.com": ["admin"],
}


def main():
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {"projectId": PROJECT_ID})
    db = firestore.client()

    now = datetime.now(timezone.utc).isoformat()

    for email, roles in USERS.items():
        doc_id = email.strip().lower()
        doc_ref = db.collection("users").document(doc_id)
        existing = doc_ref.get()
        if existing.exists:
            doc_ref.update({"roles": roles})
            print(f"Updated users/{doc_id} -> roles={roles}")
        else:
            doc_ref.set({"roles": roles, "createdAt": now})
            print(f"Created users/{doc_id} -> roles={roles}")

    print("Done.")


if __name__ == "__main__":
    main()
