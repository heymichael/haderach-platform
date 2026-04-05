"""Authenticated static-file server backed by GCS and Google OAuth."""

from __future__ import annotations

import hashlib
import hmac
import json
import mimetypes
import os
import time
from urllib.parse import quote, urlencode

import httpx
import psycopg
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, RedirectResponse, Response
from google.cloud import storage

app = FastAPI(title="Haderach Content API")

BUCKET_NAME = os.environ["CONTENT_BUCKET"]
OAUTH_CLIENT_ID = os.environ["OAUTH_CLIENT_ID"]
OAUTH_CLIENT_SECRET = os.environ["OAUTH_CLIENT_SECRET"]
SESSION_SECRET = os.environ["SESSION_SECRET"]
DATABASE_URL = os.environ["DATABASE_URL"]
SESSION_MAX_AGE = int(os.environ.get("SESSION_MAX_AGE", "86400"))  # 24h
COOKIE_NAME = "docs_session"

_gcs_client: storage.Client | None = None


def _gcs() -> storage.Client:
    global _gcs_client
    if _gcs_client is None:
        _gcs_client = storage.Client()
    return _gcs_client


def _user_exists(email: str) -> bool:
    """Check if email exists in the users table (same allowlist as the main app)."""
    normalized = email.strip().lower()
    with psycopg.connect(DATABASE_URL) as conn:
        row = conn.execute(
            "SELECT id FROM users WHERE email = %s", (normalized,)
        ).fetchone()
    return row is not None


# -- Session helpers (HMAC-signed JSON cookie) --------------------------------

def _sign(payload: str) -> str:
    sig = hmac.new(SESSION_SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return f"{payload}.{sig}"


def _unsign(value: str) -> str | None:
    parts = value.rsplit(".", 1)
    if len(parts) != 2:
        return None
    payload, sig = parts
    expected = hmac.new(SESSION_SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig, expected):
        return None
    return payload


def _create_session_cookie(email: str) -> str:
    payload = json.dumps({"email": email, "exp": int(time.time()) + SESSION_MAX_AGE})
    return _sign(payload)


def _read_session(request: Request) -> str | None:
    cookie = request.cookies.get(COOKIE_NAME)
    if not cookie:
        return None
    payload = _unsign(cookie)
    if not payload:
        return None
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return None
    if data.get("exp", 0) < time.time():
        return None
    return data.get("email")


# -- OAuth routes --------------------------------------------------------------

def _get_redirect_uri(request: Request) -> str:
    base = str(request.base_url).rstrip("/")
    if request.headers.get("x-forwarded-proto") == "https":
        base = base.replace("http://", "https://", 1)
    return base + "/auth/callback"


@app.get("/auth/login")
def auth_login(request: Request, next: str = "/"):
    params = {
        "client_id": OAUTH_CLIENT_ID,
        "redirect_uri": _get_redirect_uri(request),
        "response_type": "code",
        "scope": "openid email",
        "state": next,
        "prompt": "select_account",
    }
    return RedirectResponse(f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}")


@app.get("/auth/callback")
async def auth_callback(request: Request, code: str, state: str = "/"):
    async with httpx.AsyncClient() as client:
        token_resp = await client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": OAUTH_CLIENT_ID,
                "client_secret": OAUTH_CLIENT_SECRET,
                "redirect_uri": _get_redirect_uri(request),
                "grant_type": "authorization_code",
            },
        )
    if token_resp.status_code != 200:
        return HTMLResponse("<h1>Authentication failed</h1><p>Could not exchange code for token.</p>", status_code=401)

    id_info = token_resp.json()
    async with httpx.AsyncClient() as client:
        userinfo_resp = await client.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {id_info['access_token']}"},
        )
    if userinfo_resp.status_code != 200:
        return HTMLResponse("<h1>Authentication failed</h1><p>Could not fetch user info.</p>", status_code=401)

    userinfo = userinfo_resp.json()
    email: str = userinfo.get("email", "")

    if not _user_exists(email):
        return HTMLResponse(
            "<h1>Access denied</h1><p>Your account is not authorized. Contact an administrator.</p>",
            status_code=403,
        )

    response = RedirectResponse(state or "/")
    response.set_cookie(
        COOKIE_NAME,
        _create_session_cookie(email),
        max_age=SESSION_MAX_AGE,
        httponly=True,
        secure=True,
        samesite="lax",
    )
    return response


@app.get("/auth/logout")
def auth_logout():
    response = RedirectResponse("/auth/login")
    response.delete_cookie(COOKIE_NAME)
    return response


# -- Health check (unauthenticated) --------------------------------------------

@app.get("/health")
def health():
    return {"status": "ok"}


# -- Content serving -----------------------------------------------------------

@app.get("/{path:path}")
def serve_content(request: Request, path: str):
    email = _read_session(request)
    if not email:
        return RedirectResponse(f"/auth/login?next={quote(request.url.path)}")

    if not path or path.endswith("/"):
        path = (path or "") + "index.html"

    bucket = _gcs().bucket(BUCKET_NAME)
    blob = bucket.blob(path)

    if not blob.exists() and "." not in path.split("/")[-1]:
        blob = bucket.blob(path + ".html")
        if blob.exists():
            path = path + ".html"

    if not blob.exists():
        # Storybook's manager requests /iframe.html at the root but the file
        # lives under components/ in the bucket.  Transparently rewrite.
        if path == "iframe.html":
            blob = bucket.blob("components/iframe.html")
            path = "components/iframe.html"

    if not blob.exists():
        return HTMLResponse("<h1>404 — Not Found</h1>", status_code=404)

    content = blob.download_as_bytes()
    content_type = mimetypes.guess_type(path)[0] or "application/octet-stream"

    headers = {
        "X-Content-Type-Options": "nosniff",
        "Cache-Control": "private, max-age=300",
    }
    # Storybook embeds the preview in an iframe on the same origin.
    # Use SAMEORIGIN for components/ assets; DENY everywhere else.
    if path.startswith("components/"):
        headers["X-Frame-Options"] = "SAMEORIGIN"
    else:
        headers["X-Frame-Options"] = "DENY"

    return Response(content=content, media_type=content_type, headers=headers)
