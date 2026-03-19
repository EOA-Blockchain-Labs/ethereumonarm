#!/bin/bash
# setup-openclaw.sh — interactive setup for openclaw.json from template

TEMPLATE="/home/ethereum/.openclaw/openclaw.json.template"
OUTPUT="/home/ethereum/.openclaw/openclaw.json"
AUTH_DIR="/home/ethereum/.openclaw/agents/ethereum-node/agent"
AUTH_FILE="$AUTH_DIR/auth-profiles.json"
CRON_CONFIG="/home/ethereum/.openclaw/cron.conf"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "=================================================="
echo "  OpenClaw Ethereum Node Agent — Initial Setup"
echo "=================================================="
echo ""

# ── Check template exists ─────────────────────────────────────────────────────
if [ ! -f "$TEMPLATE" ]; then
    echo -e "${RED}Error: template not found at $TEMPLATE${NC}"
    exit 1
fi

if [ ! -r "$TEMPLATE" ]; then
    echo -e "${RED}Error: template is not readable at $TEMPLATE${NC}"
    echo "  Try: chmod 644 $TEMPLATE"
    exit 1
fi

# ── Telegram Bot Token ────────────────────────────────────────────────────────
echo "Step 1: Telegram Bot Token"
echo "  Create a bot via @BotFather on Telegram and paste the token here."
echo "  It looks like: 123456789:ABCDefGhIJKlmNoPQRsTUVwxyZ"
echo ""
while true; do
    read -p "  Bot token: " BOT_TOKEN
    if [ -z "$BOT_TOKEN" ]; then
        echo -e "  ${RED}Token cannot be empty. Try again.${NC}"
    elif [[ "$BOT_TOKEN" != *":"* ]]; then
        echo -e "  ${RED}That does not look like a valid bot token (expected format: 123456:ABC...). Try again.${NC}"
    else
        break
    fi
done
echo ""

# ── Telegram User ID ──────────────────────────────────────────────────────────
echo "Step 2: Your Telegram User ID"
echo "  Message @userinfobot on Telegram to get your numeric user ID."
echo "  It looks like: 865440373"
echo ""
while true; do
    read -p "  Telegram user ID: " TELEGRAM_USER_ID
    if [ -z "$TELEGRAM_USER_ID" ]; then
        echo -e "  ${RED}User ID cannot be empty. Try again.${NC}"
    elif ! [[ "$TELEGRAM_USER_ID" =~ ^[0-9]+$ ]]; then
        echo -e "  ${RED}User ID must be numeric. Try again.${NC}"
    else
        break
    fi
done
echo ""

# ── Generate Gateway Token ────────────────────────────────────────────────────
echo "Step 3: Gateway Token"
echo "  Generating a secure random gateway token..."
GATEWAY_TOKEN=$(openssl rand -hex 24)
if [ -z "$GATEWAY_TOKEN" ]; then
    echo -e "  ${YELLOW}Failed to generate token via openssl. Trying fallback...${NC}"
    GATEWAY_TOKEN=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 48)
fi
echo -e "  ${GREEN}Generated: $GATEWAY_TOKEN${NC}"
echo ""

# ── OpenRouter API Key ────────────────────────────────────────────────────────
echo "Step 4: OpenRouter API Key"
echo "  Sign up at https://openrouter.ai and create an API key."
echo "  It looks like: sk-or-v1-..."
echo ""
while true; do
    read -p "  OpenRouter API key: " OPENROUTER_KEY
    if [ -z "$OPENROUTER_KEY" ]; then
        echo -e "  ${RED}API key cannot be empty. Try again.${NC}"
    elif [[ "$OPENROUTER_KEY" != sk-or-* ]]; then
        echo -e "  ${YELLOW}Warning: key does not start with sk-or- — are you sure this is an OpenRouter key?${NC}"
        read -p "  Continue anyway? [y/N] " FORCE
        if [[ "$FORCE" == "y" || "$FORCE" == "Y" ]]; then
            break
        fi
    else
        break
    fi
done
echo ""

# ── Confirm ───────────────────────────────────────────────────────────────────
echo "=================================================="
echo "  Review your settings"
echo "=================================================="
echo ""
echo "  Bot token      : $BOT_TOKEN"
echo "  Telegram user  : $TELEGRAM_USER_ID"
echo "  Gateway token  : $GATEWAY_TOKEN"
echo "  OpenRouter key : ${OPENROUTER_KEY:0:12}..."
echo ""
read -p "Write configuration with these settings? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted. No files were changed."
    exit 0
fi
echo ""

# ── Backup existing config if present ────────────────────────────────────────
if [ -f "$OUTPUT" ]; then
    BACKUP="${OUTPUT}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$OUTPUT" "$BACKUP"
    echo -e "  ${YELLOW}Existing openclaw.json backed up to $BACKUP${NC}"
fi

# ── Write openclaw.json ───────────────────────────────────────────────────────
python3 - "$TEMPLATE" "$OUTPUT" "$BOT_TOKEN" "$TELEGRAM_USER_ID" "$GATEWAY_TOKEN" << 'EOF'
import sys

template_path = sys.argv[1]
output_path   = sys.argv[2]
bot_token     = sys.argv[3]
telegram_id   = sys.argv[4]
gateway_token = sys.argv[5]

with open(template_path, 'r') as f:
    content = f.read()

content = content.replace('YOUR_TELEGRAM_BOT_TOKEN', bot_token)
content = content.replace('YOUR_TELEGRAM_USER_ID', telegram_id)
content = content.replace('YOUR_GATEWAY_TOKEN', gateway_token)

with open(output_path, 'w') as f:
    f.write(content)
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: failed to write $OUTPUT${NC}"
    exit 1
fi

chmod 600 "$OUTPUT"
echo -e "  ${GREEN}openclaw.json written.${NC}"

# ── Write auth-profiles.json ──────────────────────────────────────────────────
[ ! -d "$AUTH_DIR" ] && mkdir -p "$AUTH_DIR"

python3 - "$AUTH_FILE" "$OPENROUTER_KEY" << 'EOF'
import sys, json

auth_path = sys.argv[1]
api_key   = sys.argv[2]

auth = {
    "profiles": {
        "openrouter:default": {
            "provider": "openrouter",
            "mode": "api_key",
            "apiKey": api_key
        }
    }
}

with open(auth_path, 'w') as f:
    json.dump(auth, f, indent=2)
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: failed to write $AUTH_FILE${NC}"
    exit 1
fi

chmod 600 "$AUTH_FILE"
echo -e "  ${GREEN}auth-profiles.json written.${NC}"

# ── Write cron.conf ───────────────────────────────────────────────────────────
cat > "$CRON_CONFIG" << CRONEOF
TELEGRAM_ID=$TELEGRAM_USER_ID
CRONEOF

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: failed to write $CRON_CONFIG${NC}"
    exit 1
fi

chmod 600 "$CRON_CONFIG"
echo -e "  ${GREEN}cron.conf written.${NC}"

echo ""
echo -e "${GREEN}Setup complete.${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart the OpenClaw gateway for changes to take effect:"
echo "     systemctl restart openclaw"
echo "  2. Message your bot on Telegram to verify the connection."
echo ""
