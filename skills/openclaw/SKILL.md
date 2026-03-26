---
name: email
description: "Send and receive emails. Check inbox, search, extract verification codes, send with attachments, delete processed emails."
version: 1.0.0
metadata:
  openclaw:
    requires:
      env:
        - MAILS_API_URL
        - MAILS_AUTH_TOKEN
        - MAILS_MAILBOX
      bins:
        - curl
      primaryEnv: MAILS_AUTH_TOKEN
---

# Email Skill

You have an email address and can send/receive emails via HTTP API.

## Configuration

Your email is configured via environment variables:
- `MAILS_MAILBOX` — your email address
- `MAILS_API_URL` — the Worker API endpoint
- `MAILS_AUTH_TOKEN` — authentication token

## How to Call the API

Use `curl` with the auth header. Always use the environment variables:

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox"
```

## API Reference

### Check Inbox

```bash
# List recent emails
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox"

# Search emails
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox?query=keyword"

# Filter by direction
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox?direction=inbound"

# Pagination
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox?limit=10&offset=20"
```

Response: `{ "emails": [{ "id", "mailbox", "from_address", "from_name", "subject", "code", "direction", "status", "received_at", "has_attachments", "attachment_count" }] }`

### Read Email Details

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/email?id=EMAIL_ID"
```

Returns full email with body_text, body_html, headers, metadata, and attachments list.

### Wait for Verification Code

```bash
# Wait up to 60 seconds for a verification code email
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60"

# Only codes received after a specific time
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60&since=2025-01-01T00:00:00Z"
```

Response: `{ "id": "uuid", "code": "483920", "from": "noreply@example.com", "subject": "Your code", "received_at": "..." }`
On timeout: `{ "code": null }`

### Send Email

```bash
# Simple text email
curl -s -X POST \
  -H "Authorization: Bearer $MAILS_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "$MAILS_API_URL/api/send" \
  -d "{\"from\":\"$MAILS_MAILBOX\",\"to\":[\"recipient@example.com\"],\"subject\":\"Subject\",\"text\":\"Content\"}"

# With HTML
curl -s -X POST \
  -H "Authorization: Bearer $MAILS_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "$MAILS_API_URL/api/send" \
  -d "{\"from\":\"$MAILS_MAILBOX\",\"to\":[\"recipient@example.com\"],\"subject\":\"Subject\",\"html\":\"<h1>Hello</h1>\"}"

# With attachment (base64-encoded content)
curl -s -X POST \
  -H "Authorization: Bearer $MAILS_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "$MAILS_API_URL/api/send" \
  -d "{\"from\":\"$MAILS_MAILBOX\",\"to\":[\"recipient@example.com\"],\"subject\":\"Report\",\"text\":\"See attached\",\"attachments\":[{\"filename\":\"file.pdf\",\"content\":\"BASE64_CONTENT\",\"content_type\":\"application/pdf\"}]}"
```

Send fields:
| Field | Required | Description |
|-------|----------|-------------|
| from | Yes | Must be `$MAILS_MAILBOX` |
| to | Yes | Array of recipients (max 50) |
| subject | Yes | Max 998 characters |
| text | text or html | Plain text body (max 500KB) |
| html | text or html | HTML body (max 1MB) |
| reply_to | No | Reply-to address |
| headers | No | Custom headers object |
| attachments | No | Array of `{ filename, content (base64), content_type?, content_id? }` |

### Delete Email

```bash
curl -s -X DELETE -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/email?id=EMAIL_ID"
```

Deletes email + attachments + R2 objects. Use after processing to avoid duplicates.

### Download Attachment

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/attachment?id=ATTACHMENT_ID" -o filename.pdf
```

### Check Status

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/me"
```

Returns: `{ "worker": "mails-worker", "mailbox": "...", "send": true }`

### Health Check (no auth required)

```bash
curl -s "$MAILS_API_URL/health"
```

Returns: `{ "ok": true }`

## Usage Patterns

### Sign up for a service (verification code flow)

1. Fill registration form with `$MAILS_MAILBOX`
2. Submit the form
3. Wait for code: `curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60"`
4. Parse the `code` field from the JSON response
5. Enter the code on the verification page

### Monitor inbox and process emails

1. Check inbox: `curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox"`
2. For each email, read details: `curl ... "$MAILS_API_URL/api/email?id=<id>"`
3. Process the content
4. Delete when done: `curl -s -X DELETE -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/email?id=<id>"`

### Search for specific emails

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox?query=password+reset&direction=inbound"
```

### Send a notification

```bash
curl -s -X POST -H "Authorization: Bearer $MAILS_AUTH_TOKEN" -H "Content-Type: application/json" \
  "$MAILS_API_URL/api/send" \
  -d "{\"from\":\"$MAILS_MAILBOX\",\"to\":[\"user@example.com\"],\"subject\":\"Task Complete\",\"text\":\"Your report is ready.\"}"
```

## Constraints

- `from` must match `$MAILS_MAILBOX` (enforced by server)
- Verification codes: 4-8 alphanumeric characters, supports EN/ZH/JA/KO
- Send limits: text 500KB, HTML 1MB, subject 998 chars, max 50 recipients
- Code wait timeout max 55 seconds
- Search uses FTS5 full-text search
