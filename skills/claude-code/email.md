# Email Capability — Agent Auth-Completion

You have the email address **YOUR_MAILBOX**. Your primary superpower: **complete service registrations autonomously** by receiving verification codes. You can also send/receive emails, search your inbox, download attachments, view threads, filter by label, extract structured data, manage webhooks, and monitor events in real-time.

## Config

- **Mailbox**: YOUR_MAILBOX
- **API**: YOUR_WORKER_URL
- **Token**: YOUR_AUTH_TOKEN

## Verification Code (your #1 tool)

```bash
# CLI (preferred)
mails code --to YOUR_MAILBOX --timeout 60            # Wait for verification code

# HTTP API
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"
```

Returns `{ "id": "...", "code": "483920", "from": "...", "subject": "...", "received_at": "..." }` or `{ "code": null }` if no code arrives within timeout.

**Sign up for a service:**
1. Fill form with YOUR_MAILBOX, submit
2. `mails code --to YOUR_MAILBOX --timeout 60`
3. Enter the returned code. Done.

## CLI Usage (all capabilities)

```bash
mails code --to YOUR_MAILBOX --timeout 60            # Wait for verification code
mails inbox                                          # List emails
mails inbox --query "keyword" --direction inbound    # Search/filter
mails inbox --label notification                     # Filter by label
mails inbox --threads                                # List conversation threads
mails inbox <email-id>                               # Show full email details
mails send --to user@example.com --subject "Hi" --body "Content"
mails send --to user@example.com --subject "Report" --body "See attached" --attach file.pdf
```

## HTTP API (works everywhere)

```bash
API="YOUR_WORKER_URL"
TOKEN="YOUR_AUTH_TOKEN"

# Inbox
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?query=keyword&direction=inbound"

# Filter by label (newsletter, notification, code, personal)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?label=notification"

# List conversation threads
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/threads"

# Get all emails in a thread
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/thread?id=THREAD_ID"

# Wait for verification code (long-poll)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60&since=2025-01-01T00:00:00Z"

# Read email
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Send email
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Subject","text":"Content"}'

# Reply to an email (threading via in_reply_to)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Re: Subject","text":"Reply","in_reply_to":"<message-id@example.com>"}'

# Send with CC/BCC
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"cc":["cc@example.com"],"bcc":["bcc@example.com"],"subject":"Subject","text":"Content"}'

# Send with attachment (base64-encoded content)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Report","text":"See attached","attachments":[{"filename":"report.pdf","content":"BASE64_CONTENT","content_type":"application/pdf"}]}'

# Extract structured data from an email (order, shipping, calendar, receipt, code)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/extract" -d '{"email_id":"EMAIL_ID","type":"order"}'

# Download attachment
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/attachment?id=ATTACHMENT_ID" -o file.pdf

# Delete email (after processing)
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Mailbox stats
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/stats"

# Mailbox management
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/mailbox"
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/mailbox" -d '{"webhook_url":"https://example.com/hook"}'

# Per-label webhook routing
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/mailbox/routes" -d '{"label":"code","webhook_url":"https://example.com/codes"}'

# Real-time event stream (SSE)
curl -s -N -H "Authorization: Bearer $TOKEN" "$API/api/events"

# Status / health
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/me"
curl -s "$API/health"
```

## Send Fields

| Field | Required | Description |
|-------|----------|-------------|
| `from` | Yes | Must be YOUR_MAILBOX |
| `to` | Yes | Array of recipients (max 50) |
| `subject` | Yes | Max 998 chars |
| `text` | text or html | Plain text body |
| `html` | text or html | HTML body |
| `cc` | No | Array of CC recipients |
| `bcc` | No | Array of BCC recipients |
| `reply_to` | No | Reply-to address |
| `in_reply_to` | No | Message-ID of parent email (enables threading) |
| `headers` | No | Custom headers object |
| `attachments` | No | `[{ filename, content (base64), content_type?, content_id? }]` |

Send returns: `{ "id", "provider_id", "thread_id" }`

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/send` | Send email |
| `GET /api/inbox` | List/search emails. Params: `query`, `limit`, `offset`, `direction`, `label`, `mode` (keyword/semantic/hybrid) |
| `GET /api/code?timeout=30` | Long-poll for verification code |
| `GET /api/email?id=<id>` | Get email by ID (with attachments) |
| `DELETE /api/email?id=<id>` | Delete email and attachments |
| `GET /api/attachment?id=<id>` | Download attachment |
| `GET /api/threads` | List conversation threads |
| `GET /api/thread?id=<id>` | Get all emails in a thread |
| `POST /api/extract` | Extract structured data. Body: `{ email_id, type }` type: order/shipping/calendar/receipt/code |
| `GET /api/stats` | Mailbox statistics (total, inbound, outbound, this month) |
| `GET /api/events` | SSE real-time event stream. Params: `types`, `since` |
| `GET /api/mailbox` | Mailbox info (status, webhook_url) |
| `PATCH /api/mailbox` | Update mailbox settings. Body: `{ webhook_url }` |
| `PATCH /api/mailbox/pause` | Pause mailbox |
| `PATCH /api/mailbox/resume` | Resume paused mailbox |
| `GET /api/mailbox/routes` | List per-label webhook routes |
| `PUT /api/mailbox/routes` | Upsert webhook route. Body: `{ label, webhook_url }` |
| `DELETE /api/mailbox/routes?label=X` | Delete webhook route for label |
| `GET /api/me` | Mailbox info and capabilities |
| `GET /health` | Health check (always public, no auth) |

## Common Flows

**Process inbox:**
1. `mails inbox` or `GET /api/inbox`
2. Read: `GET /api/email?id=xxx`
3. Delete when done: `DELETE /api/email?id=xxx`

**Reply to an email:**
1. `GET /api/email?id=xxx` to get the email's `message_id`
2. `POST /api/send` with `in_reply_to` set to that `message_id`

**View conversation threads:**
1. `mails inbox --threads` or `GET /api/threads`
2. Get thread details: `GET /api/thread?id=THREAD_ID`

**Filter by category:**
1. `mails inbox --label newsletter` or `GET /api/inbox?label=newsletter`
2. Available labels: newsletter, notification, code, personal

**Monitor in real-time:**
1. `GET /api/events` — SSE stream, auto-reconnects
2. Event types: `message.received`, `activation.first_received`, `activation.first_sent`

**Extract structured data:**
1. `POST /api/extract` with `{"email_id":"EMAIL_ID","type":"order"}` (type: order, shipping, calendar, receipt, code)
2. Returns structured data: order details, shipping info, calendar events, receipts, or codes

**Set up webhook routing:**
1. `PATCH /api/mailbox` with `{"webhook_url":"https://..."}` for all emails
2. `PUT /api/mailbox/routes` with `{"label":"code","webhook_url":"https://..."}` for specific labels

## Constraints

- `from` must be YOUR_MAILBOX (enforced server-side)
- Verification codes: 4-12 char alphanumeric (EN/ZH/JA/KO)
- Body limits: text 500KB, HTML 1MB; inbound storage: text 50KB, HTML 100KB
- Code timeout max 55 seconds
- Send rate limit: 100 emails/day per mailbox
