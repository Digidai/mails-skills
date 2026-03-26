# mails-skills

Give your AI agent an email address. Works with Claude Code, OpenClaw, and any LLM agent that can call HTTP APIs or run shell commands.

## What this does

After setup, your agent can:

- **Receive emails** — check inbox, search, read details
- **Send emails** — compose and send from its own address, with optional attachments
- **Extract verification codes** — sign up for services automatically
- **Monitor inbox** — react to incoming emails via polling or webhook
- **Manage emails** — delete processed emails to avoid duplicates
- **Download attachments** — access files attached to received emails

## 30-Second Quick Start (Hosted)

Already have `mails` installed? One command:

```bash
git clone https://github.com/Digidai/mails-skills && cd mails-skills && ./install.sh
```

The installer auto-detects your `~/.mails/config.json` from `mails claim` — no manual input needed.

## Full Setup (from scratch)

### Step 1: Get a mailbox

**Hosted (easiest — 2 commands):**
```bash
npm install -g mails
mails claim myagent        # Get myagent@mails.dev for free
```

**Self-hosted (your domain):**

| What you need | Why | Cost |
|---|---|---|
| A domain on Cloudflare | Email address `agent@yourdomain.com` | You already own one |
| Resend account | SMTP delivery | Free 100 emails/day |

```bash
# 1. Clone and deploy the Worker
git clone https://github.com/chekusu/mails && cd mails/worker
bun install

# 2. Create D1 database
wrangler d1 create mails
# → Copy the database_id into wrangler.toml

# 3. Initialize schema
wrangler d1 execute mails --file=schema.sql

# 4. Set secrets
wrangler secret put RESEND_API_KEY     # Your Resend API key
wrangler secret put WEBHOOK_SECRET     # Optional: for webhook HMAC signing

# 5. Deploy
wrangler deploy
# → Note the Worker URL: https://mails-worker.<subdomain>.workers.dev

# 6. Enable Email Routing in Cloudflare Dashboard
#    Domain → Email → Email Routing → Enable
#    Catch-all → Send to Worker → your-worker

# 7. Add Resend DNS records (SPF + DKIM) in Cloudflare DNS
#    See: https://resend.com/docs/dashboard/domains/introduction

# 8. Create an auth token
wrangler d1 execute mails --command \
  "INSERT INTO auth_tokens (token, mailbox) VALUES ('$(openssl rand -hex 24)', 'agent@yourdomain.com')"
```

### Step 2: Install the skill

```bash
git clone https://github.com/Digidai/mails-skills && cd mails-skills
./install.sh
```

The installer will:
1. Auto-detect your platform (Claude Code / OpenClaw)
2. Auto-read credentials from `~/.mails/config.json` (if available)
3. Install the skill to the correct location
4. Verify the connection works

**That's it.** Tell your agent "Check my inbox" to test.

### Manual install (without install.sh)

**Claude Code:**
```bash
cp skills/claude-code/email.md ~/.claude/skills/email.md
# Edit the file: replace YOUR_WORKER_URL, YOUR_AUTH_TOKEN, YOUR_MAILBOX
```

**OpenClaw:**
```bash
cp -r skills/openclaw ~/.openclaw/skills/email

# Add to your shell profile (~/.zshrc or ~/.bashrc) so OpenClaw can access them:
export MAILS_API_URL="https://your-worker.workers.dev"
export MAILS_AUTH_TOKEN="your-token"
export MAILS_MAILBOX="agent@yourdomain.com"
```

**Any other agent:**
```bash
# Copy the universal API reference into your agent's system prompt
cat skills/universal/email-api.md
```

## Skills

```
skills/
├── claude-code/
│   └── email.md           # Claude Code skill (CLAUDE.md format)
├── openclaw/
│   ├── SKILL.md            # OpenClaw AgentSkills format (YAML frontmatter + curl examples)
│   └── email-agent.md     # Alternative: plain system prompt format
└── universal/
    └── email-api.md       # Universal — Python, JavaScript, cURL examples
```

## How it works

```
Your Agent
    │
    │  "Check inbox" / "Send email" / "Get verification code"
    │
    ▼
Skill file teaches the agent what it can do
    │
    │  HTTP API call or CLI command
    │
    ▼
mails Worker (Cloudflare)
    │
    ├── Receive: Cloudflare Email Routing → Worker → D1
    ├── Send: Worker → Resend API → SMTP (with attachments)
    ├── Search: FTS5 full-text search in D1
    ├── Code: Auto-extract 4-8 digit verification codes
    ├── Attachments: Stored in R2, downloadable via API
    └── Webhook: POST notification on email received
```

## Supported Agent Platforms

| Platform | Skill Type | Install |
|---|---|---|
| Claude Code | CLAUDE.md / skill file | `./install.sh` or copy to `~/.claude/skills/` |
| OpenClaw | SKILL.md (AgentSkills) | `./install.sh` or copy to skills directory |
| Cursor | Rules file | Add `skills/universal/email-api.md` to `.cursorrules` |
| Windsurf | Rules file | Add `skills/universal/email-api.md` to `.windsurfrules` |
| Custom agents | HTTP API reference | Include `skills/universal/email-api.md` in system prompt |

## Example: Agent registers for a service

```
Agent: I need to sign up for example.com

1. Agent fills registration form with agent@yourdomain.com
2. Agent submits form
3. Agent calls: GET /api/code?timeout=60
4. API returns: { "code": "483920", ... }
5. Agent enters code on verification page
6. Registration complete!
```

## License

MIT
