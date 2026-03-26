# Skill: Email Agent

You are an AI agent with email capabilities. You can send and receive emails, extract verification codes, search your inbox, and manage messages.

## Your Mailbox

- **Email address**: YOUR_MAILBOX
- **API endpoint**: YOUR_WORKER_URL
- **Auth token**: YOUR_AUTH_TOKEN

All API requests require the header: `Authorization: Bearer YOUR_AUTH_TOKEN`

## API Reference

### Check Inbox

```
GET /api/inbox
```

Optional parameters:
- `query` — search keyword (FTS5 full-text search on subject, body, sender; also LIKE-matches email addresses)
- `limit` — number of results (default 20, max 100)
- `offset` — pagination offset
- `direction` — `inbound` (received) or `outbound` (sent)

Response: `{ "emails": [{ "id", "mailbox", "from_address", "from_name", "subject", "code", "direction", "status", "received_at", "has_attachments", "attachment_count" }] }`

### Read Email

```
GET /api/email?id=<email_id>
```

Returns full email content including body text, HTML, headers, metadata, and attachment list with downloadable flag.

### Wait for Verification Code

```
GET /api/code?timeout=60
```

Long-polling endpoint. Blocks until an email containing a verification code arrives.
Automatically extracts 4-8 character codes from email subject and body.

Optional parameters:
- `timeout` — max wait in seconds (default 30, max 55)
- `since` — ISO 8601 timestamp; only return codes from emails received after this time

Response: `{ "id": "email-uuid", "code": "483920", "from": "noreply@example.com", "subject": "Your code", "received_at": "2025-01-01T00:00:00Z" }`
On timeout: `{ "code": null }`

### Send Email

```
POST /api/send
Content-Type: application/json

{
  "from": "YOUR_MAILBOX",
  "to": ["recipient@example.com"],
  "subject": "Email subject",
  "text": "Plain text content",
  "html": "<h1>Optional HTML content</h1>",
  "reply_to": "reply@example.com",
  "headers": { "X-Custom-Header": "value" },
  "attachments": [
    {
      "filename": "report.pdf",
      "content": "base64-encoded-content",
      "content_type": "application/pdf",
      "content_id": "optional-inline-cid"
    }
  ]
}
```

Required: `from`, `to`, `subject`, and either `text` or `html` (or both).
The `from` field must match YOUR_MAILBOX.

Optional: `reply_to`, `headers`, `attachments`.

Response: `{ "id": "internal-uuid", "provider_id": "resend-id" }`

### Delete Email

```
DELETE /api/email?id=<email_id>
```

Deletes the email and its attachments (including R2 objects). Use after processing to avoid duplicates.

Response: `{ "deleted": true }`

### Download Attachment

```
GET /api/attachment?id=<attachment_id>
```

Returns the attachment file content with appropriate Content-Type and Content-Disposition headers.

### Check Status

```
GET /api/me
```

Response: `{ "worker": "mails-worker", "mailbox": "YOUR_MAILBOX", "send": true }`

### Health Check

```
GET /health
```

No authentication required. Returns: `{ "ok": true }`

## Webhook (Automatic Notifications)

When configured in the `auth_tokens` table, the Worker fires a POST webhook on every received email:

```json
{
  "event": "email.received",
  "email_id": "uuid",
  "mailbox": "you@domain.com",
  "from": "sender@example.com",
  "subject": "Email subject",
  "received_at": "2025-01-01T00:00:00Z",
  "message_id": "message-id-header",
  "has_attachments": false,
  "attachment_count": 0
}
```

Headers include `X-Webhook-Event`, `X-Webhook-Id`, and `X-Webhook-Signature` (HMAC-SHA256 if WEBHOOK_SECRET is configured).

## Usage Patterns

### Pattern 1: Account Registration

```
Goal: Sign up for a service that requires email verification

Steps:
1. Navigate to the registration page
2. Enter YOUR_MAILBOX as the email address
3. Complete and submit the registration form
4. Call GET /api/code?timeout=60
5. Receive { "id": "...", "code": "123456", "from": "...", "subject": "...", "received_at": "..." }
6. Enter the code on the verification page
7. Registration complete
```

### Pattern 2: Inbox Monitoring

```
Goal: Check for and process incoming emails

Steps:
1. Call GET /api/inbox to list recent emails
2. For each unprocessed email:
   a. Call GET /api/email?id=<id> to read the full content
   b. Extract relevant information from the email body
   c. Take action based on the content
   d. Call DELETE /api/email?id=<id> to mark as processed
```

### Pattern 3: Search for Specific Email

```
Goal: Find an email matching certain criteria

Call: GET /api/inbox?query=keyword&direction=inbound
The search covers: subject, body text (via FTS5), and email addresses (via LIKE)
```

### Pattern 4: Send Notification

```
Goal: Notify a user about a completed task

Call: POST /api/send
Body: {
  "from": "YOUR_MAILBOX",
  "to": ["user@example.com"],
  "subject": "Task Complete",
  "text": "Your requested analysis is ready. Here are the results..."
}
```

### Pattern 5: Send with Attachments

```
Goal: Send an email with file attachments

Call: POST /api/send
Body: {
  "from": "YOUR_MAILBOX",
  "to": ["user@example.com"],
  "subject": "Report",
  "text": "Please find the report attached.",
  "attachments": [
    {
      "filename": "report.pdf",
      "content": "<base64-encoded-file-content>",
      "content_type": "application/pdf"
    }
  ]
}
```

### Pattern 6: Reply to an Email

```
Goal: Reply to a received email

1. Read original email: GET /api/email?id=<id>
2. Send reply:
   POST /api/send
   Body: {
     "from": "YOUR_MAILBOX",
     "to": ["original-sender@example.com"],
     "subject": "Re: Original Subject",
     "text": "Your reply here",
     "reply_to": "YOUR_MAILBOX"
   }
```

## Constraints

- The `from` address in send requests must match YOUR_MAILBOX (enforced by the server)
- Verification code extraction supports English, Chinese, Japanese, Korean emails
- Send body limits: text 500KB, HTML 1MB
- Inbound storage limits: text 50KB, HTML 100KB (truncated on receive)
- Subject max 998 characters
- Maximum 50 recipients per email
- Code wait timeout maximum is 55 seconds
- Search uses full-text search (FTS5) with phrase matching
