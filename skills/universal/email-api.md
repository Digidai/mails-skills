# Email API for AI Agents

You have access to an email system. Use the HTTP API below to send/receive emails.

## Config

```
MAILBOX=YOUR_MAILBOX
API_URL=YOUR_WORKER_URL
AUTH_TOKEN=YOUR_AUTH_TOKEN
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/inbox | List emails. Params: `query`, `limit`, `offset`, `direction` |
| GET | /api/email?id=ID | Get email detail with body and attachments |
| GET | /api/code?timeout=60 | Wait for verification code (long-poll). Params: `timeout`, `since` |
| POST | /api/send | Send email. Body: `{ from, to[], subject, text, html, reply_to, headers, attachments }` |
| DELETE | /api/email?id=ID | Delete email and attachments |
| GET | /api/attachment?id=ID | Download attachment |
| GET | /api/me | Check mailbox info and capabilities |
| GET | /health | Health check (no auth required) |

All endpoints except `/health` require: `Authorization: Bearer AUTH_TOKEN`

## Examples

### Python

```python
import requests
import base64

API = "YOUR_WORKER_URL"
HEADERS = {"Authorization": "Bearer YOUR_AUTH_TOKEN"}

# Check inbox
emails = requests.get(f"{API}/api/inbox", headers=HEADERS).json()["emails"]

# Search
results = requests.get(f"{API}/api/inbox", headers=HEADERS, params={"query": "password"}).json()

# Filter by direction
inbound = requests.get(f"{API}/api/inbox", headers=HEADERS, params={"direction": "inbound"}).json()

# Wait for verification code
code = requests.get(f"{API}/api/code", headers=HEADERS, params={"timeout": "60"}).json()
print(code["code"])  # "483920" or None

# Wait for code received after a specific time
code = requests.get(f"{API}/api/code", headers=HEADERS, params={
    "timeout": "60",
    "since": "2025-01-01T00:00:00Z"
}).json()

# Read email details
email = requests.get(f"{API}/api/email", headers=HEADERS, params={"id": emails[0]["id"]}).json()

# Send email
requests.post(f"{API}/api/send", headers=HEADERS, json={
    "from": "YOUR_MAILBOX",
    "to": ["user@example.com"],
    "subject": "Hello",
    "text": "From your AI agent"
})

# Send with attachment
with open("report.pdf", "rb") as f:
    content = base64.b64encode(f.read()).decode()
requests.post(f"{API}/api/send", headers=HEADERS, json={
    "from": "YOUR_MAILBOX",
    "to": ["user@example.com"],
    "subject": "Report",
    "text": "See attached.",
    "attachments": [{"filename": "report.pdf", "content": content, "content_type": "application/pdf"}]
})

# Send with reply-to
requests.post(f"{API}/api/send", headers=HEADERS, json={
    "from": "YOUR_MAILBOX",
    "to": ["user@example.com"],
    "subject": "Re: Topic",
    "text": "My reply",
    "reply_to": "other@example.com"
})

# Download attachment
att = requests.get(f"{API}/api/attachment", headers=HEADERS, params={"id": "ATTACHMENT_ID"})
with open("downloaded.pdf", "wb") as f:
    f.write(att.content)

# Delete email
requests.delete(f"{API}/api/email", headers=HEADERS, params={"id": emails[0]["id"]})
```

### JavaScript / TypeScript

```typescript
const API = "YOUR_WORKER_URL"
const TOKEN = "YOUR_AUTH_TOKEN"
const headers = { "Authorization": `Bearer ${TOKEN}` }

// Check inbox
const { emails } = await fetch(`${API}/api/inbox`, { headers }).then(r => r.json())

// Wait for code
const { code } = await fetch(`${API}/api/code?timeout=60`, { headers }).then(r => r.json())

// Wait for code with since filter
const result = await fetch(`${API}/api/code?timeout=60&since=2025-01-01T00:00:00Z`, { headers }).then(r => r.json())

// Send email
await fetch(`${API}/api/send`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({
    from: "YOUR_MAILBOX",
    to: ["user@example.com"],
    subject: "Hello",
    text: "Content"
  })
})

// Send with attachment (content is base64-encoded)
await fetch(`${API}/api/send`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({
    from: "YOUR_MAILBOX",
    to: ["user@example.com"],
    subject: "Report",
    text: "See attached.",
    attachments: [{ filename: "report.pdf", content: btoa(fileContent), content_type: "application/pdf" }]
  })
})

// Delete email
await fetch(`${API}/api/email?id=${emails[0].id}`, { method: "DELETE", headers })
```

### cURL / Shell

```bash
TOKEN="YOUR_AUTH_TOKEN"
API="YOUR_WORKER_URL"

# Inbox
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"

# Search
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?query=keyword"

# Code
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"

# Code with since filter
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60&since=2025-01-01T00:00:00Z"

# Send
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Hi","text":"Hello"}'

# Send with attachment
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Report","text":"See attached","attachments":[{"filename":"file.pdf","content":"BASE64...","content_type":"application/pdf"}]}'

# Download attachment
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/attachment?id=ATTACHMENT_ID" -o file.pdf

# Delete
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Status
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/me"
```

## Webhook (Automatic Notifications)

When a webhook URL is configured for a mailbox, the Worker sends a POST request on every received email:

```json
{
  "event": "email.received",
  "email_id": "uuid",
  "mailbox": "you@domain.com",
  "from": "sender@example.com",
  "subject": "Subject",
  "received_at": "2025-01-01T00:00:00Z",
  "message_id": "message-id-header",
  "has_attachments": false,
  "attachment_count": 0
}
```

Webhook headers: `X-Webhook-Event`, `X-Webhook-Id`, `X-Webhook-Signature` (HMAC-SHA256).

## Constraints

- `from` must match your mailbox address
- Code extraction: 4-8 digit codes, supports EN/ZH/JA/KO
- Send body limits: text 500KB, HTML 1MB
- Inbound storage limits: text 50KB, HTML 100KB (truncated on receive)
- Subject max 998 characters
- Max 50 recipients per send
- Code timeout max 55 seconds
