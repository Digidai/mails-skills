---
name: Mails for Agent
description: "Complete service registrations autonomously by receiving verification codes. Also: send and receive emails, monitor inbox, search by keyword, download attachments, view threads, filter by label, extract structured data."
version: 1.7.0
metadata:
  openclaw:
    requires:
      env:
        - MAILS_API_URL
        - MAILS_AUTH_TOKEN
        - MAILS_MAILBOX
      bins: []
      primaryEnv: MAILS_AUTH_TOKEN
---

# Email Skill — Agent Auth-Completion

You have the email address `$MAILS_MAILBOX`. Your primary superpower: **complete service registrations autonomously** by receiving verification codes via `GET /api/code?timeout=60`.

Make HTTP requests to `$MAILS_API_URL` with header `Authorization: Bearer $MAILS_AUTH_TOKEN`.

**Sign up for a service:** Fill form with `$MAILS_MAILBOX` → GET /api/code?timeout=60 → enter the code. Done.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/inbox | List/search emails. Params: `query`, `limit`, `offset`, `direction`, `label`, `mode` (keyword/semantic) |
| GET | /api/email?id=ID | Full email with body, attachments, labels |
| GET | /api/code?timeout=60 | Wait for verification code (long-poll). Params: `timeout`, `since` |
| POST | /api/send | Send email. Body: `{ from, to[], subject, text, html, reply_to, headers, attachments }` |
| DELETE | /api/email?id=ID | Delete email and attachments |
| GET | /api/attachment?id=ID | Download attachment |
| GET | /api/threads | List conversation threads. Params: `limit`, `offset` |
| GET | /api/thread?id=ID | Get all emails in a thread |
| POST | /api/extract | Extract structured data. Body: `{ email_id, type }` type: order/shipping/calendar/receipt/code |
| GET | /api/me | Worker info and capabilities |
| GET | /health | Health check (no auth) |

## Request Format

All requests (except /health) require `Authorization: Bearer $MAILS_AUTH_TOKEN` header.

POST requests require `Content-Type: application/json` header.

The `to` param is optional — the API auto-scopes to the token's mailbox.

## Response Shapes

**Inbox**: `{ "emails": [{ "id", "from_address", "from_name", "subject", "code", "direction", "status", "received_at", "has_attachments", "attachment_count" }], "search_mode": "keyword" }`

**Email detail**: Full email object with `body_text`, `body_html`, `headers`, `metadata`, `labels`, `thread_id`, `attachments[]`

**Code**: `{ "id": "...", "code": "483920", "from": "...", "subject": "...", "received_at": "..." }` or `{ "code": null }`

**Threads**: `{ "threads": [{ "thread_id", "latest_email_id", "subject", "from_address", "from_name", "received_at", "message_count", "has_attachments" }] }`

**Extract**: `{ "email_id": "...", "extraction": { "type": "order", "order_id": "...", ... } }`

## Send Fields

| Field | Required | Description |
|-------|----------|-------------|
| from | Yes | Must be `$MAILS_MAILBOX` (enforced server-side) |
| to | Yes | Array of recipients (max 50) |
| subject | Yes | Max 998 characters |
| text | text or html | Plain text body |
| html | text or html | HTML body |
| reply_to | No | Reply-to address |
| headers | No | Custom headers object |
| attachments | No | `[{ filename, content (base64), content_type?, content_id? }]` |

## Labels

Emails are auto-labeled on receive: `newsletter`, `notification`, `code`, `personal`. Filter with `?label=notification`.

## Common Flows

**Sign up for a service:** Fill form with `$MAILS_MAILBOX` → GET /api/code?timeout=60 → enter the code

**Process inbox:** GET /api/inbox → GET /api/email?id=ID → DELETE /api/email?id=ID

**View threads:** GET /api/threads → GET /api/thread?id=THREAD_ID

**Extract data:** POST /api/extract with `{"email_id":"ID","type":"order"}`

## Constraints

- `from` must match `$MAILS_MAILBOX`
- Verification codes: 4-12 alphanumeric (EN/ZH/JA/KO)
- Code wait timeout max 55 seconds
- Search uses FTS5 full-text search (keyword mode) or Vectorize (semantic mode)
