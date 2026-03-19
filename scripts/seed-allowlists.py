#!/usr/bin/env python3
"""
One-time seed script to populate Firestore allowlists from the
hardcoded arrays previously in each app's accessPolicy.ts.

Prerequisites:
  pip install firebase-admin
  gcloud auth application-default login

Usage:
  python scripts/seed-allowlists.py
"""

import firebase_admin
from firebase_admin import credentials, firestore

PROJECT_ID = "haderach-ai"

ALLOWLISTS = {
    "card": {
        "surfaces": {
            "default": {
                "emails": [
                    "michael@haderachi.ai",
                    "michael@heretic.fund",
                    "mariam@heretic.fund",
                    "mariam@heretic.ventures",
                    "alexmader@gmail.com",
                ],
                "domains": ["haderach.ai"],
            },
        }
    },
    "stocks": {
        "surfaces": {
            "default": {
                "emails": [
                    "michael@haderachi.ai",
                    "michael@heretic.fund",
                    "mariam@heretic.fund",
                    "mariam@heretic.ventures",
                    "alexmader@gmail.com",
                ],
                "domains": ["haderach.ai"],
            }
        }
    },
}


def main():
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {"projectId": PROJECT_ID})
    db = firestore.client()

    for app_id, data in ALLOWLISTS.items():
        doc_ref = db.collection("allowlists").document(app_id)
        doc_ref.set(data)
        print(f"Seeded allowlists/{app_id}")

    print("Done.")


if __name__ == "__main__":
    main()
