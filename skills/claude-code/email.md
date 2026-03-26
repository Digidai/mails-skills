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

# Wait for verification code (blocks until received, max 60s)
CODE=$(mails code --to YOUR_MAILBOX --timeout 60)

# Send email
mails send --to recipient@example.com --subject "Subject" --body "Content"

# Send with attachment
mails send --to recipient@example.com --subject "Report" --body "See attached" --attach file.pdf
```

## HTTP API Usage (works everywhere, no installation needed)

```bash
API="YOUR_WORKER_URL"
TOKEN="YOUR_AUTH_TOKEN"

# Check inbox
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox"

# Search emails
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/inbox?query=keyword"

# Wait for verification code (long-poll, blocks up to timeout seconds)
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/code?timeout=60"

# Read email details
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"

# Send email
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$API/api/send" -d '{"from":"YOUR_MAILBOX","to":["recipient@example.com"],"subject":"Subject","text":"Content"}'

# Delete email (after processing)
curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API/api/email?id=EMAIL_ID"
```

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
- Verification code extraction supports 4-8 digit codes in EN/ZH/JA/KO
- Email body limits: text 50KB, html 100KB
- Max 50 recipients per email
- Code wait timeout max 55 seconds
