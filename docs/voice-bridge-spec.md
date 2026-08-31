# Voice File-Bridge — Spec

An optional, file-based message queue between this app and any external
automation (a scheduled assistant, a script, another agent). The app writes a
JSON request; your automation picks it up, runs the task, and writes a response
the app reads and speaks. Great for tasks that have no real-time API.

## Folders (under `COS_BRIDGE_ROOT`, default `~/Documents/CoS-Bridge`)

| Path | Purpose |
|------|---------|
| `requests/` | The app drops `request_*.json` files here |
| `responses/response.json` | Your automation writes the latest result here (overwritten) |
| `outputs/<task>.json` | Optional per-task cache for instant reads |

## Request format

```json
{ "task": "<task-name>", "requested_at": "<ISO 8601>", "params": {} }
```

## Response format (same for `response.json` and `outputs/<task>.json`)

```json
{
  "task": "<task-name>",
  "status": "completed" | "error",
  "completed_at": "<ISO 8601>",
  "summary": "<TTS-ready plain text — no markdown>",
  "data": { },
  "error": "<message, only when status=error>"
}
```

## Instant-read strategy

When a task is requested, the app first reads `outputs/<task>.json`. If it's
present and fresh (per a per-task max cache age), it speaks it immediately.
Otherwise it writes a request and waits for your automation to respond.

## Defining tasks

Add tasks and their trigger phrases in `app.js` (`QUICK_TASKS`). Your external
automation is responsible for recognizing the `task` name and writing the
response. This app never calls any third-party API directly for these tasks —
it only reads/writes the bridge files.
