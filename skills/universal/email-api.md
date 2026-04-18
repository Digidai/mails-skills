# Email API for AI Agents — Auth-Completion Infrastructure

Your primary superpower: **complete service registrations autonomously** by receiving verification codes. Also supports sending, receiving, inbox search, email threading, auto labels, structured data extraction, webhook routing, and real-time event streaming.

## Quick Start: Sign Up for a Service

```python
# 1. Fill the signup form with MAILBOX, submit
# 2. Wait for verification code:
code = requests.get(f"{API_URL}/api/code", headers=H, params={"timeout": "60"}).json()["code"]
# 3. Enter the code. Done.
```

## Config

```
MAILBOX=YOUR_MAILBOX
API_URL=YOUR_WORKER_URL
AUTH_TOKEN=YOUR_AUTH_TOKEN
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/inbox | List/search emails. Params: `query`, `limit`, `offset`, `direction`, `label`, `mode` (keyword/semantic/hybrid) |
| GET | /api/email?id=ID | Full email with body and attachments |
| GET | /api/code?timeout=60 | Wait for verification code (long-poll). Params: `timeout`, `since` |
| POST | /api/send | Send email. Body: `{ from, to[], cc[], bcc[], subject, text, html, reply_to, in_reply_to, headers, attachments }` |
| DELETE | /api/email?id=ID | Delete email and attachments |
| GET | /api/attachment?id=ID | Download attachment |
| GET | /api/threads | List conversation threads. Params: `limit`, `offset` |
| GET | /api/thread?id=ID | Get all emails in a thread |
| POST | /api/extract | Extract structured data. Body: `{ email_id, type }` type: order/shipping/calendar/receipt/code |
| GET | /api/stats | Mailbox statistics (total, inbound, outbound, this month) |
| GET | /api/events | SSE real-time event stream. Params: `types`, `since` |
| GET | /api/mailbox | Mailbox info (status, webhook_url) |
| PATCH | /api/mailbox | Update settings. Body: `{ webhook_url }` |
| PATCH | /api/mailbox/pause | Pause mailbox |
| PATCH | /api/mailbox/resume | Resume paused mailbox |
| GET | /api/mailbox/routes | List per-label webhook routes |
| PUT | /api/mailbox/routes | Upsert webhook route. Body: `{ label, webhook_url }` |
| DELETE | /api/mailbox/routes?label=X | Delete webhook route |
| GET | /api/me | Mailbox info and capabilities |
| GET | /health | Health check (no auth) |

All endpoints except `/health` require: `Authorization: Bearer AUTH_TOKEN`

## Python

```python
import requests, base64

API = "YOUR_WORKER_URL"
H = {"Authorization": "Bearer YOUR_AUTH_TOKEN"}

emails = requests.get(f"{API}/api/inbox", headers=H).json()["emails"]
results = requests.get(f"{API}/api/inbox", headers=H, params={"query": "password"}).json()
code = requests.get(f"{API}/api/code", headers=H, params={"timeout": "60"}).json()["code"]
email = requests.get(f"{API}/api/email", headers=H, params={"id": emails[0]["id"]}).json()

# Filter by label
notifications = requests.get(f"{API}/api/inbox", headers=H, params={"label": "notification"}).json()

# List conversation threads
threads = requests.get(f"{API}/api/threads", headers=H).json()

# Get all emails in a thread
thread = requests.get(f"{API}/api/thread", headers=H, params={"id": "THREAD_ID"}).json()

# Extract structured data from an email (type: order, shipping, calendar, receipt, code)
extracted = requests.post(f"{API}/api/extract", headers=H, json={"email_id": emails[0]["id"], "type": "order"}).json()

# Send
resp = requests.post(f"{API}/api/send", headers=H, json={
    "from": "YOUR_MAILBOX", "to": ["user@example.com"],
    "subject": "Hello", "text": "From your AI agent"
}).json()  # returns {id, provider_id, thread_id}

# Reply to an email (threading via in_reply_to)
requests.post(f"{API}/api/send", headers=H, json={
    "from": "YOUR_MAILBOX", "to": ["user@example.com"],
    "subject": "Re: Hello", "text": "Reply content",
    "in_reply_to": email["message_id"]
})

# Send with CC/BCC
requests.post(f"{API}/api/send", headers=H, json={
    "from": "YOUR_MAILBOX", "to": ["user@example.com"],
    "cc": ["cc@example.com"], "bcc": ["bcc@example.com"],
    "subject": "Hello", "text": "Content"
})

# Send with attachment
with open("report.pdf", "rb") as f:
    content = base64.b64encode(f.read()).decode()
requests.post(f"{API}/api/send", headers=H, json={
    "from": "YOUR_MAILBOX", "to": ["user@example.com"],
    "subject": "Report", "text": "See attached.",
    "attachments": [{"filename": "report.pdf", "content": content, "content_type": "application/pdf"}]
})

# Download attachment
att = requests.get(f"{API}/api/attachment", headers=H, params={"id": "ATT_ID"})
with open("file.pdf", "wb") as f:
    f.write(att.content)

# Mailbox stats
stats = requests.get(f"{API}/api/stats", headers=H).json()

# Webhook routing (per-label)
requests.put(f"{API}/api/mailbox/routes", headers=H,
    json={"label": "code", "webhook_url": "https://example.com/codes"})

# Delete
requests.delete(f"{API}/api/email", headers=H, params={"id": emails[0]["id"]})
```

## JavaScript / TypeScript

```typescript
const API = "YOUR_WORKER_URL"
const headers = { "Authorization": "Bearer YOUR_AUTH_TOKEN" }

const { emails } = await fetch(`${API}/api/inbox`, { headers }).then(r => r.json())
const { code } = await fetch(`${API}/api/code?timeout=60`, { headers }).then(r => r.json())
const email = await fetch(`${API}/api/email?id=${emails[0].id}`, { headers }).then(r => r.json())

// Filter by label
const notifications = await fetch(`${API}/api/inbox?label=notification`, { headers }).then(r => r.json())

// List threads
const threads = await fetch(`${API}/api/threads`, { headers }).then(r => r.json())

// Get thread details
const thread = await fetch(`${API}/api/thread?id=THREAD_ID`, { headers }).then(r => r.json())

// Extract structured data (type: order, shipping, calendar, receipt, code)
const extracted = await fetch(`${API}/api/extract`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({ email_id: emails[0].id, type: "order" })
}).then(r => r.json())

// Send (returns {id, provider_id, thread_id})
const sent = await fetch(`${API}/api/send`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({
    from: "YOUR_MAILBOX", to: ["user@example.com"],
    subject: "Hello", text: "Content"
  })
}).then(r => r.json())

// Reply to an email (threading via in_reply_to)
await fetch(`${API}/api/send`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({
    from: "YOUR_MAILBOX", to: ["user@example.com"],
    subject: "Re: Hello", text: "Reply",
    in_reply_to: email.message_id
  })
})

// SSE real-time events
const es = new EventSource(`${API}/api/events`, { headers })
es.onmessage = (e) => console.log(JSON.parse(e.data))

// Stats
const stats = await fetch(`${API}/api/stats`, { headers }).then(r => r.json())

// Delete
await fetch(`${API}/api/email?id=${emails[0].id}`, { method: "DELETE", headers })
```

## cURL

```bash
TOKEN="YOUR_AUTH_TOKEN"
API="YOUR_WORKER_URL"

curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?query=keyword"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?label=notification"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/threads"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/thread?id=THREAD_ID"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Hi","text":"Hello"}'
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Re: Hi","text":"Reply","in_reply_to":"<msg-id@example.com>"}'
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/extract" -d '{"email_id":"EMAIL_ID","type":"order"}'
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/attachment?id=ATT_ID" -o file.pdf
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/stats"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/mailbox"
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/mailbox/routes" -d '{"label":"code","webhook_url":"https://example.com/codes"}'
curl -s -N -H "Authorization: Bearer $TOKEN" "$API/api/events"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/me"
curl -s "$API/health"
```

## Webhook

Incoming emails trigger a POST to the configured webhook URL:

```json
{
  "event": "message.received",
  "email_id": "uuid",
  "mailbox": "you@domain.com",
  "from": "sender@example.com",
  "subject": "Subject",
  "received_at": "2025-01-01T00:00:00Z",
  "has_attachments": false,
  "attachment_count": 0
}
```

Headers: `X-Webhook-Event`, `X-Webhook-Id`, `X-Webhook-Signature` (HMAC-SHA256).

Smart routing: set per-label webhook URLs via `PUT /api/mailbox/routes` to route `code`, `newsletter`, `notification`, or `personal` emails to different endpoints.

## Constraints

- `from` must match your mailbox address (enforced server-side)
- Verification codes: 4-12 char alphanumeric (EN/ZH/JA/KO)
- Body limits: text 500KB, HTML 1MB; inbound storage: text 50KB, HTML 100KB
- Max 50 recipients, subject max 998 chars, code timeout max 55s
- Send rate limit: 100 emails/day per mailbox
