#!/bin/bash
# mails-skills installer
# Usage: ./install.sh

set -e

echo "mails-skills installer"
echo ""

# Detect platform
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

# Collect config
echo ""
read -p "Worker API URL (e.g. https://mails-worker.xxx.workers.dev): " WORKER_URL
if [ -z "$WORKER_URL" ]; then
  echo "Error: Worker API URL is required"; exit 1
fi

read -p "Auth Token: " AUTH_TOKEN
if [ -z "$AUTH_TOKEN" ]; then
  echo "Error: Auth Token is required"; exit 1
fi

read -p "Mailbox address (e.g. hi@yourdomain.com): " MAILBOX
if [ -z "$MAILBOX" ]; then
  echo "Error: Mailbox address is required"; exit 1
fi

# Strip trailing slash from WORKER_URL
WORKER_URL="${WORKER_URL%/}"

# Escape sed special characters in replacement strings (& and \ are special in sed)
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

    # Also install mails CLI if not present
    if ! command -v mails &> /dev/null; then
      echo ""
      read -p "Install mails CLI? (recommended) [y/N]: " install_cli
      if [ "$install_cli" = "y" ] || [ "$install_cli" = "Y" ]; then
        if ! command -v npm &> /dev/null; then
          echo "Error: npm is not installed. Install Node.js first: https://nodejs.org/"
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
        break
      fi
    done
    if [ "$INSTALLED" = false ]; then
      mkdir -p "./email"
      cp "$SKILL_SRC" "./email/SKILL.md"
      echo "[ok] Skill saved to ./email/SKILL.md (OpenClaw directory not found)"
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

echo ""
echo "Done! Your agent now has email at: $MAILBOX"

if [ "$PLATFORM" = "openclaw" ]; then
  echo ""
  echo "Set these environment variables for your OpenClaw agent:"
  echo "  export MAILS_API_URL=\"$WORKER_URL\""
  echo "  export MAILS_AUTH_TOKEN=\"$AUTH_TOKEN\""
  echo "  export MAILS_MAILBOX=\"$MAILBOX\""
  echo ""
  echo "Add them to your shell profile (~/.bashrc or ~/.zshrc) or OpenClaw's .env file."
fi

echo ""
echo "Test it:"
echo "  curl -s -H \"Authorization: Bearer $AUTH_TOKEN\" $WORKER_URL/api/me"
