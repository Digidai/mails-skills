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
| GET | /api/code?timeout=60 | Wait for verification code (long-poll) |
| POST | /api/send | Send email. Body: `{ from, to[], subject, text/html }` |
| DELETE | /api/email?id=ID | Delete email and attachments |
| GET | /api/attachment?id=ID | Download attachment |
| GET | /api/me | Check mailbox info and capabilities |
| GET | /health | Health check (no auth required) |

All endpoints except `/health` require: `Authorization: Bearer AUTH_TOKEN`

## Examples

### Python

```python
import requests

API = "YOUR_WORKER_URL"
HEADERS = {"Authorization": "Bearer YOUR_AUTH_TOKEN"}

# Check inbox
emails = requests.get(f"{API}/api/inbox", headers=HEADERS).json()["emails"]

# Search
results = requests.get(f"{API}/api/inbox", headers=HEADERS, params={"query": "password"}).json()

# Wait for verification code
code = requests.get(f"{API}/api/code", headers=HEADERS, params={"timeout": "60"}).json()
print(code["code"])  # "483920" or None

# Send email
requests.post(f"{API}/api/send", headers=HEADERS, json={
    "from": "YOUR_MAILBOX",
    "to": ["user@example.com"],
    "subject": "Hello",
    "text": "From your AI agent"
})

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
```

### cURL / Shell

```bash
TOKEN="YOUR_AUTH_TOKEN"
API="YOUR_WORKER_URL"

# Inbox
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"

# Code
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"

# Send
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Hi","text":"Hello"}'
```

## Constraints

- `from` must match your mailbox address
- Code extraction: 4-8 digit codes, supports EN/ZH/JA/KO
- Body limits: text 50KB, HTML 100KB
- Max 50 recipients per send
- Code timeout max 55 seconds
