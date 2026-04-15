<p align="center">
  <h1 align="center">mails-skills</h1>
  <p align="center">
    Your AI agent can now sign up for any service. Verification codes handled automatically.
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
    <a href="#supported-platforms"><img src="https://img.shields.io/badge/platforms-Claude_Code_%7C_OpenClaw_%7C_Cursor_%7C_Any_Agent-brightgreen.svg" alt="Platforms"></a>
    <a href="https://www.npmjs.com/package/mails-agent"><img src="https://img.shields.io/npm/v/mails-agent.svg?label=mails-agent%20CLI" alt="npm version"></a>
  </p>
</p>

---

**Your agent hits "enter verification code" and stops.** Not anymore. `mails-skills` gives any AI agent the ability to receive verification codes and complete service registrations autonomously. One API call: `GET /api/code?timeout=60`.

## What Your Agent Can Do

| Capability | Example |
|---|---|
| **Auto-register for services** | **Full flow: fill form, wait for code, verify. Zero human intervention.** |
| **Extract verification codes** | **"Sign up on example.com and enter the code"** |
| Receive emails | "Check my inbox for new messages" |
| Send emails | "Send a summary report to alice@company.com" |
| Search inbox | "Find all emails from GitHub" |
| Download attachments | "Get the PDF from that invoice email" |
| Conversation threads | "Show me the full thread with Alice" |
| Filter by label | "Show me all newsletters" (newsletter, notification, code, personal) |
| Extract structured data | "Extract the order details from that confirmation email" (order, shipping, calendar, receipt) |

## Quick Start

### Option A: Hosted (2 commands)

```bash
npm install -g mails-agent    # Install the CLI
mails claim myagent           # Claim myagent@mails0.com (free)
```

Then install the skill:

```bash
git clone https://github.com/Digidai/mails-skills && cd mails-skills && ./install.sh
```

The installer auto-detects your config from `mails claim` -- no manual input needed.

### Option B: Self-hosted

<details>
<summary>Click to expand self-hosted setup</summary>

You need: a domain on Cloudflare + a free [Resend](https://resend.com) account.

```bash
# 1. Deploy the Worker
git clone https://github.com/Digidai/mails && cd mails/worker
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
Skill file (installed locally, teaches the agent the API)
    |
    |  HTTP API calls
    v
mails Worker (Cloudflare Workers + D1 + R2)
    |-- Receive: Cloudflare Email Routing -> Worker -> D1
    |-- Send:    Worker -> Resend API -> SMTP
    |-- Search:  FTS5 full-text search
    |-- Codes:   Auto-extract 4-12 char verification codes
    |-- Files:   Attachments in R2, downloadable via API
    |-- Threads: Conversation threading by subject/references
    |-- Labels:  Auto-categorize (newsletter, notification, code, personal)
    |-- Extract: Structured data extraction (order, shipping, calendar, receipt)
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

<details>
<summary>Manual install (without install.sh)</summary>

**Claude Code:**
```bash
cp skills/claude-code/email.md ~/.claude/skills/email.md
# Edit: replace YOUR_WORKER_URL, YOUR_AUTH_TOKEN, YOUR_MAILBOX
```

**OpenClaw:**
```bash
cp -r skills/openclaw ~/.openclaw/skills/email
# Add to ~/.zshrc:
export MAILS_API_URL="https://your-worker.workers.dev"
export MAILS_AUTH_TOKEN="your-token"
export MAILS_MAILBOX="agent@yourdomain.com"
```

**Any other agent:**
```bash
# Copy skills/universal/email-api.md into your agent's system prompt
```
</details>

## Example: Agent Signs Up for a Service

```
You:   "Sign up for an account on example.com using our email"

Agent: 1. Opens example.com/register
       2. Fills in the form with agent@mails0.com
       3. Submits the form
       4. Calls GET /api/code?timeout=60
       5. Receives { "code": "483920" }
       6. Enters 483920 on the verification page
       7. "Done! Account created successfully."
```

## Non-Interactive Install (CI / Automation)

```bash
./install.sh --url https://your-worker.workers.dev --token YOUR_TOKEN --mailbox agent@example.com

# Or with environment variables:
MAILS_URL=https://your-worker.workers.dev MAILS_TOKEN=YOUR_TOKEN MAILS_MAILBOX=agent@example.com ./install.sh
```

## Captcha Limitation

Most modern SaaS services (Render, Figma, etc.) use captcha challenges that block fully autonomous agent registration. mails-skills handles the email/OTP side, captcha is a browser-layer problem.

**Recommended solutions:**
- [Steel](https://steel.dev) -- open-source browser API with built-in captcha solving
- [Browserbase](https://www.browserbase.com) -- cloud browsers with captcha solving + Agent Identity
- [CapSolver](https://www.capsolver.com) -- captcha solving API ($0.80/1K solves), browser extension available
- [Web Bot Auth](https://datatracker.ietf.org/doc/html/draft-meunier-web-bot-auth-architecture) -- emerging IETF protocol for verified bot identity (Cloudflare, AWS, Akamai support)

## Troubleshooting

| Problem | Solution |
|---|---|
| `python3 not found` | `brew install python3` (macOS) or `apt install python3` (Linux) |
| `invalid auth token` | Re-run `mails claim` or check `~/.mails/config.json` |
| Cannot reach Worker URL | Verify the URL and that the Worker is deployed |
| Agent doesn't know about email | Check skill file exists: `ls ~/.claude/skills/email.md` |
| Verification code not found | The email may lack a parseable code. Read the full email with `GET /api/email?id=...` |
| `mails claim` hangs | Check your internet connection; the hosted service may be temporarily unavailable |

## Project Structure

```
skills/
  claude-code/email.md     # Claude Code skill
  openclaw/SKILL.md        # OpenClaw AgentSkills format
  universal/email-api.md   # Universal API reference (Python, JS, cURL)
install.sh                 # Interactive + non-interactive installer
```

## Ecosystem

| Project | Install | Description |
|---|---|---|
| **[mails](https://github.com/Digidai/mails)** | `npm i -g mails-agent` | CLI + SDK + Worker |
| **[mails-mcp](https://github.com/Digidai/mails-mcp)** | `npx mails-agent-mcp` | MCP Server (10 tools) |
| **[mails-python](https://github.com/Digidai/mails-python)** | `pip install mails-agent` | Python SDK |
| **[mails-skills](https://github.com/Digidai/mails-skills)** (this repo) | `npx mails-skills` | Agent Skills |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
