#!/bin/bash
# mails-skills installer
# Usage: ./install.sh

set -e

echo "🔧 mails-skills installer"
echo ""

# Detect platform
PLATFORM=""
if [ -d "$HOME/.claude" ]; then
  PLATFORM="claude-code"
  echo "✓ Detected: Claude Code"
fi
if [ -d "$HOME/.openclaw" ] || [ -d "$HOME/openclaw" ]; then
  PLATFORM="openclaw"
  echo "✓ Detected: OpenClaw"
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
    *) echo "Invalid choice"; exit 1 ;;
  esac
fi

# Collect config
echo ""
read -p "Worker API URL (e.g. https://mails-worker.xxx.workers.dev): " WORKER_URL
read -p "Auth Token: " AUTH_TOKEN
read -p "Mailbox address (e.g. hi@yourdomain.com): " MAILBOX

echo ""
echo "Configuring for $PLATFORM..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case $PLATFORM in
  claude-code)
    SKILL_SRC="$SCRIPT_DIR/skills/claude-code/email.md"
    SKILL_DST="$HOME/.claude/skills/email.md"
    mkdir -p "$HOME/.claude/skills"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    echo "✓ Skill installed to $SKILL_DST"

    # Also install mails CLI if not present
    if ! command -v mails &> /dev/null; then
      echo ""
      read -p "Install mails CLI? (recommended) [y/N]: " install_cli
      if [ "$install_cli" = "y" ] || [ "$install_cli" = "Y" ]; then
        npm install -g mails
        mails config set worker_url "$WORKER_URL"
        mails config set worker_token "$AUTH_TOKEN"
        mails config set mailbox "$MAILBOX"
        mails config set default_from "$MAILBOX"
        echo "✓ mails CLI configured"
      fi
    else
      mails config set worker_url "$WORKER_URL"
      mails config set worker_token "$AUTH_TOKEN"
      mails config set mailbox "$MAILBOX"
      mails config set default_from "$MAILBOX"
      echo "✓ mails CLI configured"
    fi
    ;;

  openclaw)
    SKILL_SRC="$SCRIPT_DIR/skills/openclaw/email-agent.md"
    # Try common OpenClaw skill paths
    for dir in "$HOME/.openclaw/skills" "$HOME/openclaw/skills" "./skills"; do
      if [ -d "$dir" ] || [ -d "$(dirname "$dir")" ]; then
        mkdir -p "$dir"
        sed -e "s|YOUR_WORKER_URL|$WORKER_URL|g" \
            -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN|g" \
            -e "s|YOUR_MAILBOX|$MAILBOX|g" \
            "$SKILL_SRC" > "$dir/email-agent.md"
        echo "✓ Skill installed to $dir/email-agent.md"
        break
      fi
    done
    ;;

  universal)
    SKILL_SRC="$SCRIPT_DIR/skills/universal/email-api.md"
    SKILL_DST="./email-api.md"
    sed -e "s|YOUR_WORKER_URL|$WORKER_URL|g" \
        -e "s|YOUR_AUTH_TOKEN|$AUTH_TOKEN|g" \
        -e "s|YOUR_MAILBOX|$MAILBOX|g" \
        "$SKILL_SRC" > "$SKILL_DST"
    echo "✓ Skill saved to $SKILL_DST"
    echo "  Add this file to your agent's system prompt or context."
    ;;
esac

echo ""
echo "Done! Your agent now has email at: $MAILBOX"
echo ""
echo "Test it:"
echo "  curl -s -H \"Authorization: Bearer $AUTH_TOKEN\" $WORKER_URL/api/me"
