---
name: Mails for Agent
description: "Send and receive emails via HTTP API. Use when the agent needs to: sign up for services and enter verification codes, monitor an inbox for incoming messages, send notifications or reports, search emails by keyword, download attachments, or interact with any email-based workflow."
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

You have the email address `$MAILS_MAILBOX`. Use `curl` with `$MAILS_API_URL` and `$MAILS_AUTH_TOKEN`.

## API Reference

### Inbox

```bash
# List recent emails
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox"

# Search / filter / paginate
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/inbox?query=keyword&direction=inbound&limit=10&offset=0"
```

Response: `{ "emails": [{ "id", "from_address", "from_name", "subject", "code", "direction", "status", "received_at", "has_attachments", "attachment_count" }] }`

### Read Email

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/email?id=EMAIL_ID"
```

Returns full email with `body_text`, `body_html`, headers, metadata, and attachments list.

### Wait for Verification Code

```bash
# Long-poll up to 60s; returns { "code": "483920" } or { "code": null }
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60"

# Only codes received after a timestamp
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60&since=2025-01-01T00:00:00Z"
```

### Send Email

```bash
curl -s -X POST \
  -H "Authorization: Bearer $MAILS_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  "$MAILS_API_URL/api/send" \
  -d "{\"from\":\"$MAILS_MAILBOX\",\"to\":[\"recipient@example.com\"],\"subject\":\"Subject\",\"text\":\"Content\"}"
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

### Download Attachment

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/attachment?id=ATTACHMENT_ID" -o filename.pdf
```

### Status / Health

```bash
curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/me"
# Returns: { "worker": "mails-worker", "mailbox": "...", "send": true }

curl -s "$MAILS_API_URL/health"   # No auth required
```

## Common Flows

**Sign up for a service:**
1. Fill form with `$MAILS_MAILBOX`, submit
2. `curl -s -H "Authorization: Bearer $MAILS_AUTH_TOKEN" "$MAILS_API_URL/api/code?timeout=60"`
3. Enter the `code` from the response

**Process inbox:**
1. `GET /api/inbox` -- list emails
2. `GET /api/email?id=<id>` -- read details
3. `DELETE /api/email?id=<id>` -- clean up after processing

## Constraints

- `from` must match `$MAILS_MAILBOX` (enforced server-side)
- Verification codes: 4-8 alphanumeric characters (EN/ZH/JA/KO)
- Code wait timeout max 55 seconds
- Search uses FTS5 full-text search
