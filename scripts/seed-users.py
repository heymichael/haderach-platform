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
    "michael@haderach.ai": ["admin", "finance_admin"],
    "michael@heretic.fund": ["admin", "finance_admin"],
    "huy@heretic.fund": ["admin", "finance_admin"],
    "mariam@heretic.fund": ["admin", "finance_admin"],
    "mariam@heretic.ventures": ["admin", "finance_admin"],
    "alexmader@gmail.com": ["haderach_user"],
    "binamader@gmail.com": ["haderach_user"],
    "suman@heretic.fund": ["admin"],
    "michael.d.mader@gmail.com": ["user"],
}


def main():
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {"projectId": PROJECT_ID})
    db = firestore.client()

    now = datetime.now(timezone.utc).isoformat()

    for email, new_roles in USERS.items():
        doc_id = email.strip().lower()
        doc_ref = db.collection("users").document(doc_id)
        existing = doc_ref.get()
        if existing.exists:
            old_roles = existing.to_dict().get("roles", [])
            merged = sorted(set(old_roles) | set(new_roles))
            doc_ref.update({"roles": merged})
            print(f"Updated users/{doc_id} -> roles={merged}  (was {old_roles})")
        else:
            doc_ref.set({"roles": new_roles, "createdAt": now})
            print(f"Created users/{doc_id} -> roles={new_roles}")

    print("Done.")


if __name__ == "__main__":
    main()
