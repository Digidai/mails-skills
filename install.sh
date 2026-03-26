#!/bin/bash
# mails-skills installer
# Usage: ./install.sh

set -e

echo "mails-skills installer"
echo ""

# --- Auto-detect mails config ---
MAILS_CONFIG="$HOME/.mails/config.json"
AUTO_WORKER_URL=""
AUTO_AUTH_TOKEN=""
AUTO_MAILBOX=""

if [ -f "$MAILS_CONFIG" ]; then
  echo "[ok] Found mails config at $MAILS_CONFIG"
  AUTO_WORKER_URL=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('worker_url', ''))" 2>/dev/null || true)
  AUTO_AUTH_TOKEN=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('api_key', '') or c.get('worker_token', ''))" 2>/dev/null || true)
  AUTO_MAILBOX=$(python3 -c "import json; c=json.load(open('$MAILS_CONFIG')); print(c.get('mailbox', '') or c.get('default_from', ''))" 2>/dev/null || true)

  # For hosted users, worker_url might not be set — use the default hosted URL
  if [ -z "$AUTO_WORKER_URL" ] && [ -n "$AUTO_AUTH_TOKEN" ]; then
    AUTO_WORKER_URL="https://mails-dev-worker.o-u-turing.workers.dev"
  fi

  if [ -n "$AUTO_WORKER_URL" ] && [ -n "$AUTO_AUTH_TOKEN" ] && [ -n "$AUTO_MAILBOX" ]; then
    echo "  Worker URL: $AUTO_WORKER_URL"
    echo "  Mailbox:    $AUTO_MAILBOX"
    echo "  Token:      ${AUTO_AUTH_TOKEN:0:8}..."
    echo ""
    read -p "Use these settings? [Y/n]: " use_auto
    if [ "$use_auto" = "n" ] || [ "$use_auto" = "N" ]; then
      AUTO_WORKER_URL=""
      AUTO_AUTH_TOKEN=""
      AUTO_MAILBOX=""
    fi
  fi
fi

# --- Detect platform ---
PLATFORM=""
if [ -d "$HOME/.claude" ]; then
  PLATFORM="claude-code"
  echo "[ok] Detected: Claude Code"
fi
if [ -d "$HOME/.openclaw" ] || [ -d "$HOME/openclaw" ]; then
  PLATFORM="openclaw"
  echo "[ok] Detected: OpenClaw"
fi

if [ -z "$PLATFORM" ]; then
  echo "Select your platform:"
  echo "  1) Claude Code"
  echo "  2) OpenClaw"
  echo "  3) Other (universal HTTP API)"
  read -p "Choice [1-3]: " choice
  case $choice in
    1) PLATFORM="claude-code" ;;
    2) PLATFORM="openclaw" ;;
    3) PLATFORM="universal" ;;
    *) echo "Error: Invalid choice"; exit 1 ;;
  esac
fi

# --- Collect config (use auto-detected values as defaults) ---
echo ""

if [ -n "$AUTO_WORKER_URL" ]; then
  WORKER_URL="$AUTO_WORKER_URL"
else
  read -p "Worker API URL (e.g. https://mails-worker.xxx.workers.dev): " WORKER_URL
  if [ -z "$WORKER_URL" ]; then
    echo "Error: Worker API URL is required"; exit 1
  fi
fi

if [ -n "$AUTO_AUTH_TOKEN" ]; then
  AUTH_TOKEN="$AUTO_AUTH_TOKEN"
else
  read -p "Auth Token: " AUTH_TOKEN
  if [ -z "$AUTH_TOKEN" ]; then
    echo "Error: Auth Token is required"; exit 1
  fi
fi

if [ -n "$AUTO_MAILBOX" ]; then
  MAILBOX="$AUTO_MAILBOX"
else
  read -p "Mailbox address (e.g. hi@yourdomain.com): " MAILBOX
  if [ -z "$MAILBOX" ]; then
    echo "Error: Mailbox address is required"; exit 1
  fi
fi

# Strip trailing slash from WORKER_URL
WORKER_URL="${WORKER_URL%/}"

# Escape sed special characters in replacement strings
escape_sed() { printf '%s' "$1" | sed 's/[&\\/|]/\\&/g'; }
WORKER_URL_ESC="$(escape_sed "$WORKER_URL")"
AUTH_TOKEN_ESC="$(escape_sed "$AUTH_TOKEN")"
MAILBOX_ESC="$(escape_sed "$MAILBOX")"

echo ""
echo "Configuring for $PLATFORM..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case $PLATFORM in
  claude-code)
    SKILL_SRC="$SCRIPT_DIR/skills/claude-code/email.md"
    SKILL_DST="$HOME/.claude/skills/email.md"
    mkdir -p "$HOME/.claude/skills"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL_ESC|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN_ESC|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX_ESC|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    echo "[ok] Skill installed to $SKILL_DST"

    # Also install/configure mails CLI
    if ! command -v mails &> /dev/null; then
      echo ""
      read -p "Install mails CLI? (recommended) [Y/n]: " install_cli
      if [ "$install_cli" != "n" ] && [ "$install_cli" != "N" ]; then
        if ! command -v npm &> /dev/null; then
          echo "Warning: npm not found. Install Node.js first: https://nodejs.org/"
          echo "  Then run: npm install -g mails"
        else
          npm install -g mails
          mails config set worker_url "$WORKER_URL"
          mails config set worker_token "$AUTH_TOKEN"
          mails config set mailbox "$MAILBOX"
          mails config set default_from "$MAILBOX"
          echo "[ok] mails CLI configured"
        fi
      fi
    else
      mails config set worker_url "$WORKER_URL"
      mails config set worker_token "$AUTH_TOKEN"
      mails config set mailbox "$MAILBOX"
      mails config set default_from "$MAILBOX"
      echo "[ok] mails CLI configured"
    fi
    ;;

  openclaw)
    SKILL_SRC="$SCRIPT_DIR/skills/openclaw/SKILL.md"
    INSTALLED=false
    # Try common OpenClaw skill paths
    for dir in "$HOME/.openclaw/skills" "$HOME/openclaw/skills"; do
      if [ -d "$(dirname "$dir")" ]; then
        mkdir -p "$dir/email"
        cp "$SKILL_SRC" "$dir/email/SKILL.md"
        echo "[ok] Skill installed to $dir/email/SKILL.md"
        INSTALLED=true

        # Write .env file next to SKILL.md
        cat > "$dir/email/.env" <<ENVEOF
MAILS_API_URL=$WORKER_URL
MAILS_AUTH_TOKEN=$AUTH_TOKEN
MAILS_MAILBOX=$MAILBOX
ENVEOF
        echo "[ok] Environment variables written to $dir/email/.env"
        break
      fi
    done
    if [ "$INSTALLED" = false ]; then
      mkdir -p "./email"
      cp "$SKILL_SRC" "./email/SKILL.md"
      cat > "./email/.env" <<ENVEOF
MAILS_API_URL=$WORKER_URL
MAILS_AUTH_TOKEN=$AUTH_TOKEN
MAILS_MAILBOX=$MAILBOX
ENVEOF
      echo "[ok] Skill saved to ./email/SKILL.md (OpenClaw directory not found)"
      echo "[ok] Environment variables written to ./email/.env"
      echo "  Move the email/ folder to your OpenClaw skills directory."
    fi
    ;;

  universal)
    SKILL_SRC="$SCRIPT_DIR/skills/universal/email-api.md"
    SKILL_DST="./email-api.md"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL_ESC|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN_ESC|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX_ESC|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    echo "[ok] Skill saved to $SKILL_DST"
    echo "  Add this file to your agent's system prompt or context."
    ;;
esac

# --- Verify installation ---
echo ""
echo "Verifying connection..."
VERIFY=$(curl -s --max-time 10 -H "Authorization: Bearer $AUTH_TOKEN" "$WORKER_URL/api/me" 2>/dev/null || echo '{"error":"connection failed"}')

if echo "$VERIFY" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'mailbox' in d else 1)" 2>/dev/null; then
  VERIFIED_MAILBOX=$(echo "$VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('mailbox',''))" 2>/dev/null)
  CAN_SEND=$(echo "$VERIFY" | python3 -c "import sys,json; print('yes' if json.load(sys.stdin).get('send') else 'no')" 2>/dev/null)
  echo "[ok] Connected to Worker"
  echo "  Mailbox: $VERIFIED_MAILBOX"
  echo "  Send:    $CAN_SEND"
  echo ""
  echo "All set! Your agent now has email at: $VERIFIED_MAILBOX"
elif echo "$VERIFY" | grep -q "Unauthorized"; then
  echo "[!!] Connection failed: invalid auth token"
  echo "  Check your token and try again."
  exit 1
elif echo "$VERIFY" | grep -q "connection failed"; then
  echo "[!!] Connection failed: cannot reach $WORKER_URL"
  echo "  Check the Worker URL and try again."
  exit 1
else
  echo "[!!] Unexpected response: $VERIFY"
  echo "  The skill was installed but could not verify the connection."
fi

echo ""
echo "Quick test — tell your agent: \"Check my inbox\""
