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
- `query` — search keyword (searches subject, body, sender)
- `limit` — number of results (default 20, max 100)
- `offset` — pagination offset
- `direction` — `inbound` (received) or `outbound` (sent)

Response: `{ "emails": [{ "id", "from_address", "from_name", "subject", "received_at", "direction", "status", "has_attachments", "attachment_count" }] }`

### Read Email

```
GET /api/email?id=<email_id>
```

Returns full email content including body text, HTML, headers, and attachment list.

### Wait for Verification Code

```
GET /api/code?timeout=60
```

Long-polling endpoint. Blocks until an email containing a verification code arrives.
Automatically extracts 4-8 character codes from email subject and body.

- `timeout` — max wait in seconds (default 30, max 55)

Response: `{ "code": "483920", "from": "noreply@example.com", "subject": "Your code" }`
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
  "html": "<h1>Optional HTML content</h1>"
}
```

Either `text` or `html` is required (or both). The `from` field must match YOUR_MAILBOX.

Response: `{ "id": "internal-uuid", "provider_id": "resend-id" }`

### Delete Email

```
DELETE /api/email?id=<email_id>
```

Deletes the email and its attachments. Use after processing to avoid duplicates.

Response: `{ "deleted": true }`

### Download Attachment

```
GET /api/attachment?id=<attachment_id>
```

Returns the attachment file content.

### Check Status

```
GET /api/me
```

Response: `{ "worker": "mails-worker", "mailbox": "YOUR_MAILBOX", "send": true }`

## Usage Patterns

### Pattern 1: Account Registration

```
Goal: Sign up for a service that requires email verification

Steps:
1. Navigate to the registration page
2. Enter YOUR_MAILBOX as the email address
3. Complete and submit the registration form
4. Call GET /api/code?timeout=60
5. Receive { "code": "123456" }
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
The search covers: subject, body text, sender address, sender name, verification codes
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

## Constraints

- The `from` address in send requests must be YOUR_MAILBOX (enforced by the server)
- Verification code extraction supports English, Chinese, Japanese, Korean emails
- Email body size limits: text 50KB, HTML 100KB
- Maximum 50 recipients per email
- Code wait timeout maximum is 55 seconds
- Search uses full-text search (FTS5) with phrase matching
