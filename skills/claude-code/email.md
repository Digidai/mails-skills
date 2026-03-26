# Email Capability

You have an email address and can send/receive emails.

## Configuration

- **Mailbox**: YOUR_MAILBOX
- **Worker API**: YOUR_WORKER_URL
- **Auth Token**: YOUR_AUTH_TOKEN

## CLI Usage (recommended if `mails` is installed)

```bash
# Check inbox
mails inbox

# Search emails
mails inbox --query "keyword"

# Filter by direction
mails inbox --direction inbound

# Wait for verification code (blocks until received, max 60s)
CODE=$(mails code --to YOUR_MAILBOX --timeout 60)

# Wait for code received after a specific time
CODE=$(mails code --to YOUR_MAILBOX --timeout 60 --since "2025-01-01T00:00:00Z")

# Send email
mails send --to recipient@example.com --subject "Subject" --body "Content"

# Send with attachment
mails send --to recipient@example.com --subject "Report" --body "See attached" --attach file.pdf

# Send with reply-to
mails send --to recipient@example.com --subject "Subject" --body "Content" --reply-to other@example.com
```

## HTTP API Usage (works everywhere, no installation needed)

```bash
API="YOUR_WORKER_URL"
TOKEN="YOUR_AUTH_TOKEN"

# Check inbox
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"

# Search emails
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?query=keyword"

# Filter by direction (inbound or outbound)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?direction=inbound"

# Wait for verification code (long-poll, blocks up to timeout seconds)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"

# Wait for code with since filter (only codes received after this timestamp)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60&since=2025-01-01T00:00:00Z"

# Read email details
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Send email
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["recipient@example.com"],"subject":"Subject","text":"Content"}'

# Send with attachments (content is base64-encoded)
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["recipient@example.com"],"subject":"Report","text":"See attached","attachments":[{"filename":"report.pdf","content":"BASE64_CONTENT","content_type":"application/pdf"}]}'

# Send with reply-to and custom headers
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["recipient@example.com"],"subject":"Re: Topic","text":"Content","reply_to":"other@example.com","headers":{"X-Custom":"value"}}'

# Download attachment
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/attachment?id=ATTACHMENT_ID" -o file.pdf

# Delete email (after processing)
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Check mailbox status
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/me"
```

## Send API Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `from` | string | Yes | Must match YOUR_MAILBOX |
| `to` | string[] | Yes | Recipients (max 50) |
| `subject` | string | Yes | Email subject (max 998 chars) |
| `text` | string | text or html | Plain text body |
| `html` | string | text or html | HTML body |
| `reply_to` | string | No | Reply-to address |
| `headers` | object | No | Custom email headers |
| `attachments` | array | No | `[{ filename, content (base64), content_type?, content_id? }]` |

## Common Scenarios

### Sign up for a service
1. Fill registration form with YOUR_MAILBOX
2. Submit registration
3. Run `mails code --to YOUR_MAILBOX --timeout 60` or call `GET /api/code?timeout=60`
4. Enter the returned code on the verification page

### Monitor inbox for triggers
1. `mails inbox` or `GET /api/inbox` to check for new emails
2. `mails inbox --query "keyword"` to search for specific emails
3. Read the email: `GET /api/email?id=xxx`
4. Process the email content
5. Delete when done: `DELETE /api/email?id=xxx`

### Send a notification
```bash
mails send --to user@example.com --subject "Task Complete" --body "Your report is ready."
```

## Constraints

- `from` address must be YOUR_MAILBOX (security restriction)
- Verification code extraction supports 4-8 character alphanumeric codes in EN/ZH/JA/KO
- Send body limits: text 500KB, html 1MB
- Inbound storage limits: text 50KB, html 100KB (truncated on receive)
- Max 50 recipients per email
- Subject max 998 characters
- Code wait timeout max 55 seconds
