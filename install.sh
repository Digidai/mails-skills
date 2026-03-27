#!/bin/bash
# mails-skills installer
# Gives your AI agent an email address.
#
# Usage:
#   ./install.sh                     Interactive (auto-detects config)
#   ./install.sh --help              Show help
#   ./install.sh --url U --token T --mailbox M   Non-interactive
#   MAILS_URL=U MAILS_TOKEN=T MAILS_MAILBOX=M ./install.sh   Env-based

set -e

VERSION="1.0.0"

# --- Colors (disable if not a terminal) ---
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  DIM='\033[2m'
  RESET='\033[0m'
else
  GREEN='' YELLOW='' RED='' BOLD='' DIM='' RESET=''
fi

ok()   { echo -e "  ${GREEN}[ok]${RESET} $1"; }
warn() { echo -e "  ${YELLOW}[!!]${RESET} $1"; }
err()  { echo -e "  ${RED}[error]${RESET} $1"; }
step() { echo -e "\n${BOLD}$1${RESET}"; }

# --- Help ---
show_help() {
  cat <<'HELP'
mails-skills installer -- give your AI agent an email address

USAGE
  ./install.sh                                    Interactive (recommended)
  ./install.sh --url URL --token TOKEN --mailbox ADDR   Non-interactive
  ./install.sh --platform claude-code             Force platform selection
  ./install.sh --help                             Show this help
  ./install.sh --version                          Show version

OPTIONS
  --url URL          Worker API URL (e.g. https://mails-worker.xxx.workers.dev)
  --token TOKEN      Auth token for the API
  --mailbox ADDR     Your agent's email address (e.g. agent@mails0.com)
  --platform NAME    Force platform: claude-code, openclaw, or universal
  --help, -h         Show this help message
  --version, -v      Show version

ENVIRONMENT VARIABLES (alternative to flags)
  MAILS_URL          Same as --url
  MAILS_TOKEN        Same as --token
  MAILS_MAILBOX      Same as --mailbox

EXAMPLES
  # Hosted (after running: npm install -g mails-agent && mails claim myagent)
  ./install.sh

  # Self-hosted, non-interactive
  ./install.sh --url https://mails.example.workers.dev --token abc123 --mailbox bot@example.com

  # CI / automation
  MAILS_URL=https://mails.example.workers.dev MAILS_TOKEN=abc123 MAILS_MAILBOX=bot@example.com ./install.sh

HELP
  exit 0
}

# --- Parse flags ---
FLAG_URL="" FLAG_TOKEN="" FLAG_MAILBOX="" FLAG_PLATFORM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)    show_help ;;
    --version|-v) echo "mails-skills installer v$VERSION"; exit 0 ;;
    --url)        FLAG_URL="$2"; shift 2 ;;
    --token)      FLAG_TOKEN="$2"; shift 2 ;;
    --mailbox)    FLAG_MAILBOX="$2"; shift 2 ;;
    --platform)   FLAG_PLATFORM="$2"; shift 2 ;;
    *)            err "Unknown option: $1"; echo "Run ./install.sh --help for usage."; exit 1 ;;
  esac
done

# Env vars as fallback for flags
[ -z "$FLAG_URL" ] && FLAG_URL="${MAILS_URL:-}"
[ -z "$FLAG_TOKEN" ] && FLAG_TOKEN="${MAILS_TOKEN:-}"
[ -z "$FLAG_MAILBOX" ] && FLAG_MAILBOX="${MAILS_MAILBOX:-}"

NON_INTERACTIVE=false
if [ -n "$FLAG_URL" ] && [ -n "$FLAG_TOKEN" ] && [ -n "$FLAG_MAILBOX" ]; then
  NON_INTERACTIVE=true
fi

# --- Banner ---
echo ""
echo -e "${BOLD}mails-skills installer${RESET} v$VERSION"
echo "Give your AI agent an email address."
echo ""

# --- Check dependencies ---
step "Checking dependencies..."

if ! command -v curl &> /dev/null; then
  err "curl is required but not installed."
  exit 1
fi
ok "curl"

if ! command -v python3 &> /dev/null; then
  err "python3 is required but not installed."
  echo "    Install Python 3: https://www.python.org/downloads/"
  exit 1
fi
ok "python3"

# --- Auto-detect mails config ---
MAILS_CONFIG="$HOME/.mails/config.json"
AUTO_WORKER_URL=""
AUTO_AUTH_TOKEN=""
AUTO_MAILBOX=""
IS_HOSTED=false

if [ "$NON_INTERACTIVE" = false ] && [ -f "$MAILS_CONFIG" ]; then
  step "Detecting configuration..."

  if ! python3 -c "import json; json.load(open('$MAILS_CONFIG'))" 2>/dev/null; then
    warn "$MAILS_CONFIG exists but is not valid JSON -- skipping."
  else
    AUTO_WORKER_URL=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('worker_url', ''))" 2>/dev/null || true)
    AUTO_AUTH_TOKEN=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('api_key', '') or c.get('worker_token', ''))" 2>/dev/null || true)
    AUTO_MAILBOX=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('mailbox', '') or c.get('default_from', ''))" 2>/dev/null || true)

    # Hosted users may not have worker_url set
    if [ -z "$AUTO_WORKER_URL" ] && [ -n "$AUTO_AUTH_TOKEN" ]; then
      AUTO_WORKER_URL="https://mails-worker.genedai.workers.dev"
      IS_HOSTED=true
    fi

    if [ -n "$AUTO_WORKER_URL" ] && [ -n "$AUTO_AUTH_TOKEN" ] && [ -n "$AUTO_MAILBOX" ]; then
      ok "Found config from mails CLI"
      echo "    Mailbox:  $AUTO_MAILBOX"
      echo "    API URL:  $AUTO_WORKER_URL"
      echo "    Token:    ${AUTO_AUTH_TOKEN:0:8}..."
      echo ""
      read -p "  Use these settings? [Y/n]: " use_auto
      if [ "$use_auto" = "n" ] || [ "$use_auto" = "N" ]; then
        AUTO_WORKER_URL=""
        AUTO_AUTH_TOKEN=""
        AUTO_MAILBOX=""
        IS_HOSTED=false
      fi
    fi
  fi
fi

# --- Use flags/env if provided ---
if [ "$NON_INTERACTIVE" = true ]; then
  WORKER_URL="$FLAG_URL"
  AUTH_TOKEN="$FLAG_TOKEN"
  MAILBOX="$FLAG_MAILBOX"
fi

# --- Detect platform ---
step "Detecting platform..."

PLATFORM="$FLAG_PLATFORM"
HAS_CLAUDE=false
HAS_OPENCLAW=false
[ -d "$HOME/.claude" ] && HAS_CLAUDE=true
{ [ -d "$HOME/.openclaw" ] || [ -d "$HOME/openclaw" ]; } && HAS_OPENCLAW=true

if [ -z "$PLATFORM" ]; then
  if [ "$HAS_CLAUDE" = true ] && [ "$HAS_OPENCLAW" = false ]; then
    PLATFORM="claude-code"
    ok "Detected Claude Code"
  elif [ "$HAS_OPENCLAW" = true ] && [ "$HAS_CLAUDE" = false ]; then
    PLATFORM="openclaw"
    ok "Detected OpenClaw"
  elif [ "$NON_INTERACTIVE" = true ]; then
    PLATFORM="claude-code"
    ok "Defaulting to Claude Code (non-interactive)"
  else
    echo "  Select your platform:"
    echo "    1) Claude Code"
    echo "    2) OpenClaw"
    echo "    3) Other (universal HTTP API reference)"
    echo ""
    read -p "  Choice [1-3]: " choice
    case $choice in
      1) PLATFORM="claude-code" ;;
      2) PLATFORM="openclaw" ;;
      3) PLATFORM="universal" ;;
      *) err "Invalid choice. Run ./install.sh again."; exit 1 ;;
    esac
  fi
fi

# --- Collect config ---
if [ "$NON_INTERACTIVE" = false ]; then
  if [ -n "$AUTO_WORKER_URL" ]; then
    WORKER_URL="$AUTO_WORKER_URL"
  elif [ -z "${WORKER_URL:-}" ]; then
    step "Configuration..."
    read -p "  Worker API URL (e.g. https://mails-worker.xxx.workers.dev): " WORKER_URL
    if [ -z "$WORKER_URL" ]; then
      err "Worker API URL is required."; exit 1
    fi
  fi

  if [ -n "$AUTO_AUTH_TOKEN" ]; then
    AUTH_TOKEN="$AUTO_AUTH_TOKEN"
  elif [ -z "${AUTH_TOKEN:-}" ]; then
    read -p "  Auth Token: " AUTH_TOKEN
    if [ -z "$AUTH_TOKEN" ]; then
      err "Auth Token is required."; exit 1
    fi
  fi

  if [ -n "$AUTO_MAILBOX" ]; then
    MAILBOX="$AUTO_MAILBOX"
  elif [ -z "${MAILBOX:-}" ]; then
    read -p "  Mailbox address (e.g. agent@mails0.com): " MAILBOX
    if [ -z "$MAILBOX" ]; then
      err "Mailbox address is required."; exit 1
    fi
  fi
fi

# Strip trailing slash
WORKER_URL="${WORKER_URL%/}"

# Escape sed special characters
escape_sed() { printf '%s' "$1" | sed 's/[&\\/|]/\\&/g'; }
WORKER_URL_ESC="$(escape_sed "$WORKER_URL")"
AUTH_TOKEN_ESC="$(escape_sed "$AUTH_TOKEN")"
MAILBOX_ESC="$(escape_sed "$MAILBOX")"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Install skill ---
step "Installing skill for $PLATFORM..."

case $PLATFORM in
  claude-code)
    SKILL_SRC="$SCRIPT_DIR/skills/claude-code/email.md"
    SKILL_DST="$HOME/.claude/skills/email.md"
    mkdir -p "$HOME/.claude/skills"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL_ESC|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN_ESC|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX_ESC|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    ok "Skill installed to $SKILL_DST"

    # Configure mails CLI
    configure_mails_cli() {
      if [ "$IS_HOSTED" = true ]; then
        mails config set mailbox "$MAILBOX"
        mails config set default_from "$MAILBOX"
      else
        mails config set worker_url "$WORKER_URL"
        mails config set worker_token "$AUTH_TOKEN"
        mails config set mailbox "$MAILBOX"
        mails config set default_from "$MAILBOX"
      fi
      ok "mails CLI configured"
    }
    if ! command -v mails &> /dev/null; then
      if [ "$NON_INTERACTIVE" = false ]; then
        echo ""
        read -p "  Install mails CLI? (recommended for terminal use) [Y/n]: " install_cli
        if [ "$install_cli" != "n" ] && [ "$install_cli" != "N" ]; then
          if ! command -v npm &> /dev/null; then
            warn "npm not found. Install Node.js first: https://nodejs.org/"
            echo "    Then run: npm install -g mails-agent"
          else
            npm install -g mails-agent
            configure_mails_cli
          fi
        fi
      fi
    else
      configure_mails_cli
    fi
    ;;

  openclaw)
    SKILL_SRC="$SCRIPT_DIR/skills/openclaw/SKILL.md"
    INSTALLED=false
    for dir in "$HOME/.openclaw/skills" "$HOME/openclaw/skills"; do
      if [ -d "$(dirname "$dir")" ]; then
        mkdir -p "$dir/email"
        cp "$SKILL_SRC" "$dir/email/SKILL.md"
        ok "Skill installed to $dir/email/SKILL.md"
        INSTALLED=true
        break
      fi
    done
    if [ "$INSTALLED" = false ]; then
      mkdir -p "./email"
      cp "$SKILL_SRC" "./email/SKILL.md"
      ok "Skill saved to ./email/SKILL.md"
      echo "    Move the email/ folder to your OpenClaw skills directory."
    fi

    # Set environment variables in shell profile
    EXPORT_LINES="
# mails-skills (email for AI agents)
export MAILS_API_URL=\"$WORKER_URL\"
export MAILS_AUTH_TOKEN=\"$AUTH_TOKEN\"
export MAILS_MAILBOX=\"$MAILBOX\""

    SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
      SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      SHELL_RC="$HOME/.bash_profile"
    fi

    if [ -n "$SHELL_RC" ]; then
      if grep -q "MAILS_API_URL" "$SHELL_RC" 2>/dev/null; then
        ok "MAILS_* env vars already in $SHELL_RC (not modified)"
      else
        echo "$EXPORT_LINES" >> "$SHELL_RC"
        ok "Added MAILS_* env vars to $SHELL_RC"
        echo "    Run: source $SHELL_RC  (or open a new terminal)"
      fi
    else
      warn "Could not find shell profile (.zshrc / .bashrc / .bash_profile)."
      echo "    Add these lines manually:"
      echo "$EXPORT_LINES"
    fi
    ;;

  universal)
    SKILL_SRC="$SCRIPT_DIR/skills/universal/email-api.md"
    SKILL_DST="./email-api.md"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL_ESC|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN_ESC|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX_ESC|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    ok "API reference saved to $SKILL_DST"
    echo "    Add this file to your agent's system prompt or context."
    ;;

  *)
    err "Unknown platform: $PLATFORM"
    echo "    Valid options: claude-code, openclaw, universal"
    exit 1
    ;;
esac

# --- Verify connection ---
step "Verifying connection..."

VERIFY=$(curl -s --max-time 10 -H "Authorization: Bearer $AUTH_TOKEN" "$WORKER_URL/api/me" 2>/dev/null || echo '{"error":"connection failed"}')

if echo "$VERIFY" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'mailbox' in d else 1)" 2>/dev/null; then
  VERIFIED_MAILBOX=$(echo "$VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('mailbox',''))" 2>/dev/null)
  CAN_SEND=$(echo "$VERIFY" | python3 -c "import sys,json; print('yes' if json.load(sys.stdin).get('send') else 'no')" 2>/dev/null)
  ok "Connected to API"
  echo "    Mailbox:  $VERIFIED_MAILBOX"
  echo "    Can send: $CAN_SEND"
elif echo "$VERIFY" | grep -q "Unauthorized"; then
  err "Invalid auth token."
  echo "    Check your token in ~/.mails/config.json or re-run: mails claim <name>"
  exit 1
elif echo "$VERIFY" | grep -q "connection failed"; then
  err "Cannot reach $WORKER_URL"
  echo "    Check the URL and make sure the Worker is deployed."
  exit 1
else
  warn "Unexpected response from API: $VERIFY"
  echo "    The skill was installed, but the connection could not be verified."
fi

# --- Success ---
echo ""
echo -e "${GREEN}${BOLD}Setup complete!${RESET}"
echo ""
echo "  Your agent's email: $MAILBOX"
echo ""
echo "  Test it now -- tell your agent:"
echo -e "  ${DIM}\"Check my inbox\"${RESET}"
echo ""
