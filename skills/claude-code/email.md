# Email Capability

You have the email address **YOUR_MAILBOX**. You can send/receive emails, wait for verification codes, search your inbox, and download attachments.

## Config

- **Mailbox**: YOUR_MAILBOX
- **API**: YOUR_WORKER_URL
- **Token**: YOUR_AUTH_TOKEN

## CLI Usage (preferred if `mails` is installed)

```bash
mails inbox                                          # List emails
mails inbox --query "keyword" --direction inbound    # Search/filter
mails code --to YOUR_MAILBOX --timeout 60            # Wait for verification code
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

# Wait for verification code (long-poll)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60&since=2025-01-01T00:00:00Z"

# Read email
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Send email
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Subject","text":"Content"}'

# Send with attachment (base64-encoded content)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["user@example.com"],"subject":"Report","text":"See attached","attachments":[{"filename":"report.pdf","content":"BASE64_CONTENT","content_type":"application/pdf"}]}'

# Download attachment
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/attachment?id=ATTACHMENT_ID" -o file.pdf

# Delete email (after processing)
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

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
| `reply_to` | No | Reply-to address |
| `headers` | No | Custom headers object |
| `attachments` | No | `[{ filename, content (base64), content_type?, content_id? }]` |

## Common Flows

**Sign up for a service:**
1. Fill form with YOUR_MAILBOX, submit
2. `mails code --to YOUR_MAILBOX --timeout 60` or `GET /api/code?timeout=60`
3. Enter the returned code

**Process inbox:**
1. `mails inbox` or `GET /api/inbox`
2. Read: `GET /api/email?id=xxx`
3. Delete when done: `DELETE /api/email?id=xxx`

## Constraints

- `from` must be YOUR_MAILBOX (enforced server-side)
- Verification codes: 4-8 char alphanumeric (EN/ZH/JA/KO)
- Body limits: text 500KB, HTML 1MB; inbound storage: text 50KB, HTML 100KB
- Code timeout max 55 seconds
