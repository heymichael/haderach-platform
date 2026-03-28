---
id: "59"
title: "Agent chat cancellation — backend mid-loop abort support"
status: pending
group: vendors
phase: vendors
priority: low
type: improvement
tags: [agent, ux, performance, chat, agent-strategy]
dependencies: []
effort: medium
created: 2026-03-24
---

# Agent chat cancellation — backend mid-loop abort support

## Context

The vendors chat agent UI is getting a "stop" button that aborts the in-flight fetch request. Today, the frontend abort is sufficient because:

- The `/chat` endpoint is synchronous request-response. When the client disconnects, the backend finishes its current work and discards the response when it tries to write to the closed connection.
- **Waiting on OpenAI API**: The `openai_client.chat.completions.create()` call in `app.py` (line ~120) is blocking. A client disconnect won't interrupt it — the current OpenAI call and tool loop run to completion, the response is generated, and then discarded. No harm, just wasted compute.
- **Running `execute_python` (sandbox)**: The sandbox thread runs to completion or hits its 120s timeout. The `ThreadPoolExecutor` cleanup in the `finally` block already handles teardown.
- **Running Firestore queries** (`search_vendors`, `query_spend`): These are fast (sub-10s) and stateless. No cleanup needed.
- The chat endpoint is effectively read-only — no writes to Firestore, no state mutations — so there are no side effects to clean up from an aborted request.

## Problem

The "discard on disconnect" behavior is safe but wasteful. If the agent is mid-loop (e.g. on round 3 of 10 tool calls), it will finish all remaining rounds before discovering the client is gone. This burns OpenAI tokens and keeps the Cloud Run instance busy.

## Proposed solution

Add backend support for mid-loop cancellation so the agent stops between tool-call rounds when the client has disconnected:

1. **Check client connection between rounds**: In the `for _ in range(max_rounds)` loop in `app.py`, check whether the client is still connected before starting the next OpenAI call. FastAPI/Starlette exposes `request.is_disconnected()` for this.
2. **Streaming alternative** (larger change): Convert `/chat` to a streaming endpoint (SSE or chunked response). This gives the frontend real-time tool-call progress and makes cancellation natural — closing the stream stops the loop. This would also enable showing "Searching vendors..." / "Querying spend..." status in the UI.
3. **Cancel sandbox execution**: If `execute_python` is running when the user hits stop, the sandbox thread continues until its 120s timeout. A cancellation token pattern (threading.Event checked by the sandbox) could allow earlier termination, but this is complex and low priority since most sandbox runs finish in <30s.

## Recommendation

Option 1 (connection check between rounds) is the minimal viable change — a few lines in `app.py`. Option 2 (streaming) is the better long-term architecture but is a larger lift. Option 3 is not worth the complexity unless sandbox timeouts become a real problem.

## Validation

- Verify that aborting mid-request does not leave any orphaned state (Firestore writes, leaked threads, etc.)
- Confirm the stop button in the UI properly aborts the fetch (AbortController)
- Test that the backend stops issuing new OpenAI calls after client disconnect (option 1)
- Measure token/compute savings from early termination
