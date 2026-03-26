<p align="center">
  <h1 align="center">mails-skills</h1>
  <p align="center">
    Give your AI agent a real email address. Send, receive, and extract verification codes.
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
    <a href="#supported-platforms"><img src="https://img.shields.io/badge/platforms-Claude_Code_%7C_OpenClaw_%7C_Cursor_%7C_Any_Agent-brightgreen.svg" alt="Platforms"></a>
    <a href="https://www.npmjs.com/package/mails"><img src="https://img.shields.io/npm/v/mails.svg?label=mails%20CLI" alt="npm version"></a>
  </p>
</p>

---

**Your agent needs an email address.** To sign up for services, receive verification codes, send notifications, or monitor an inbox -- it needs email. `mails-skills` gives any LLM agent that ability in under 2 minutes.

## What can your agent do with email?

| Capability | Example |
|---|---|
| Receive emails | "Check my inbox for new messages" |
| Send emails | "Send a summary report to alice@company.com" |
| Extract verification codes | "Sign up on example.com and enter the code" |
| Search inbox | "Find all emails from GitHub" |
| Download attachments | "Get the PDF from that invoice email" |
| Auto-register for services | Full flow: fill form, wait for code, verify |

## Quick Start (2 minutes)

### Option A: Hosted (easiest -- 2 commands)

```bash
npm install -g mails          # Install the CLI
mails claim myagent           # Claim myagent@mails.dev (free)
```

Then install the skill for your agent:

```bash
git clone https://github.com/Digidai/mails-skills && cd mails-skills && ./install.sh
```

The installer auto-detects your config from `mails claim` -- no manual input needed.

### Option B: Self-hosted (your own domain)

<details>
<summary>Click to expand self-hosted setup</summary>

You need: a domain on Cloudflare + a free [Resend](https://resend.com) account.

```bash
# 1. Deploy the Worker
git clone https://github.com/chekusu/mails && cd mails/worker
bun install

# 2. Create D1 database
wrangler d1 create mails
# Copy the database_id into wrangler.toml

# 3. Initialize schema
wrangler d1 execute mails --file=schema.sql

# 4. Set secrets
wrangler secret put RESEND_API_KEY
wrangler secret put WEBHOOK_SECRET     # Optional: for webhook signing

# 5. Deploy
wrangler deploy
# Note the Worker URL: https://mails-worker.<subdomain>.workers.dev

# 6. Enable Email Routing in Cloudflare Dashboard
#    Domain > Email > Email Routing > Enable
#    Catch-all > Send to Worker > your-worker

# 7. Add Resend DNS records (SPF + DKIM) in Cloudflare DNS
#    See: https://resend.com/docs/dashboard/domains/introduction

# 8. Create an auth token
wrangler d1 execute mails --command \
  "INSERT INTO auth_tokens (token, mailbox) VALUES ('$(openssl rand -hex 24)', 'agent@yourdomain.com')"
```

Then install the skill:

```bash
git clone https://github.com/Digidai/mails-skills && cd mails-skills && ./install.sh
```

</details>

## How It Works

```
Your Agent (Claude Code / OpenClaw / Cursor / any LLM)
    |
    |  "Check inbox" / "Send email" / "Get verification code"
    v
Skill file (installed locally, teaches the agent what it can do)
    |
    |  HTTP API calls
    v
mails Worker (Cloudflare Workers + D1 + R2)
    |
    |-- Receive: Cloudflare Email Routing -> Worker -> D1 database
    |-- Send:    Worker -> Resend API -> SMTP delivery
    |-- Search:  FTS5 full-text search across all emails
    |-- Codes:   Auto-extract 4-8 digit verification codes
    |-- Files:   Attachments stored in R2, downloadable via API
    '-- Hooks:   Webhook POST on every received email
```

## Supported Platforms

| Platform | How it works | Install |
|---|---|---|
| **Claude Code** | Skill file in `~/.claude/skills/` | `./install.sh` (auto-detected) |
| **OpenClaw** | SKILL.md with env vars | `./install.sh` (auto-detected) |
| **Cursor** | Rules file | Add `skills/universal/email-api.md` to `.cursorrules` |
| **Windsurf** | Rules file | Add `skills/universal/email-api.md` to `.windsurfrules` |
| **Any agent** | HTTP API reference | Include `skills/universal/email-api.md` in system prompt |

### Manual Install (without install.sh)

<details>
<summary>Claude Code</summary>

```bash
cp skills/claude-code/email.md ~/.claude/skills/email.md
# Edit the file: replace YOUR_WORKER_URL, YOUR_AUTH_TOKEN, YOUR_MAILBOX
```
</details>

<details>
<summary>OpenClaw</summary>

```bash
cp -r skills/openclaw ~/.openclaw/skills/email

# Add to ~/.zshrc or ~/.bashrc:
export MAILS_API_URL="https://your-worker.workers.dev"
export MAILS_AUTH_TOKEN="your-token"
export MAILS_MAILBOX="agent@yourdomain.com"
```
</details>

<details>
<summary>Any other agent</summary>

```bash
cat skills/universal/email-api.md
# Copy this into your agent's system prompt or context file
```
</details>

## Example: Agent Signs Up for a Service

```
You:   "Sign up for an account on example.com using our email"

Agent: 1. Opens example.com/register
       2. Fills in the form with agent@mails.dev
       3. Submits the form
       4. Calls GET /api/code?timeout=60  (waits for verification email)
       5. Receives { "code": "483920" }
       6. Enters 483920 on the verification page
       7. "Done! Account created successfully."
```

## Non-Interactive Install (CI / Automation)

```bash
./install.sh --url https://your-worker.workers.dev --token YOUR_TOKEN --mailbox agent@example.com
```

Or with environment variables:

```bash
MAILS_URL=https://your-worker.workers.dev \
MAILS_TOKEN=YOUR_TOKEN \
MAILS_MAILBOX=agent@example.com \
./install.sh
```

## Troubleshooting

| Problem | Solution |
|---|---|
| `install.sh` says "python3 not found" | Install Python 3: `brew install python3` (macOS) or `apt install python3` (Linux) |
| "Connection failed: invalid auth token" | Re-run `mails claim` or check your token in `~/.mails/config.json` |
| "Cannot reach Worker URL" | Check the URL is correct and the Worker is deployed |
| Agent says "I don't know how to send email" | Verify the skill file was installed: `ls ~/.claude/skills/email.md` |
| Verification code not arriving | Check `GET /api/inbox` -- the email might not have a parseable code. Read the full email instead. |

## Project Structure

```
skills/
  claude-code/
    email.md           # Claude Code skill (CLAUDE.md format)
  openclaw/
    SKILL.md           # OpenClaw AgentSkills format (YAML frontmatter)
  universal/
    email-api.md       # Universal API reference (Python, JS, cURL)
install.sh             # Interactive + non-interactive installer
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

## Ecosystem

```
┌─────────────────────────────────────────────────────────────┐
│                        mails ecosystem                       │
│                                                              │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────┐  │
│  │  mails CLI   │    │  mails Worker    │    │   mails   │  │
│  │  & SDK       │───▶│  (Cloudflare)    │◀───│  -skills  │  │
│  │              │    │                  │    │           │  │
│  │  npm i mails │    │  Receive + Send  │    │  Agent    │  │
│  │              │    │  + Search + Code │    │  Skills   │  │
│  └──────────────┘    └──────────────────┘    └───────────┘  │
│    Human / Script        Infrastructure        AI Agents    │
│                                                              │
│  github.com/Digidai/mails    ←→    github.com/Digidai/mails-skills  │
└─────────────────────────────────────────────────────────────┘
```

| Project | What it is | Who uses it |
|---|---|---|
| **[mails](https://github.com/Digidai/mails)** | Email server (Worker) + CLI + SDK | Developers deploying email infra |
| **[mails-skills](https://github.com/Digidai/mails-skills)** (this repo) | Skill files for AI agents | AI agents (Claude Code, OpenClaw, etc.) |

## License

[MIT](LICENSE)
