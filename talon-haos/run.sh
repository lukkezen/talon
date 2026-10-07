#!/bin/sh
set -eu

OPTIONS="/data/options.json"
BASE="/data/talon"
CONFIG_DIR="$BASE/config"
STATE_DIR="$BASE/state"
PERSONA_DIR="$BASE/personas/assistant"
SKILLS_DIR="$BASE/skills"
SUBAGENTS_DIR="$BASE/subagents"
USERDATA_DIR="$BASE/userdata"
WHATSAPP_AUTH_DIR="$BASE/baileys-auth"
CONFIG_FILE="$CONFIG_DIR/talond.yaml"

mkdir -p "$CONFIG_DIR" "$STATE_DIR" "$PERSONA_DIR" "$SKILLS_DIR" "$SUBAGENTS_DIR" "$USERDATA_DIR" "$WHATSAPP_AUTH_DIR"

if [ ! -f "$OPTIONS" ]; then
  echo "[talon] Home Assistant options file not found: $OPTIONS"
  exit 1
fi

OPENAI_API_KEY="$(jq -r '.openai_api_key // ""' "$OPTIONS")"
OPENAI_MODEL="$(jq -r '.openai_model // "gpt-5.4"' "$OPTIONS")"
TELEGRAM_BOT_TOKEN="$(jq -r '.telegram_bot_token // ""' "$OPTIONS")"
TELEGRAM_CHAT_ID="$(jq -r '.telegram_chat_id // ""' "$OPTIONS")"
WHATSAPP_ENABLED="$(jq -r '.whatsapp_enabled // true' "$OPTIONS")"
WHATSAPP_SELF_CHAT="$(jq -r '.whatsapp_self_chat // true' "$OPTIONS")"
WHATSAPP_TRIGGER_WORD="$(jq -r '.whatsapp_trigger_word // "@Talon"' "$OPTIONS")"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "[talon] openai_api_key is empty. Set it in the add-on Configuration tab."
  exit 1
fi

export OPENAI_API_KEY
export TELEGRAM_BOT_TOKEN

MODEL_JSON="$(printf '%s' "$OPENAI_MODEL" | jq -Rs .)"
CHAT_ID_JSON="$(printf '%s' "$TELEGRAM_CHAT_ID" | jq -Rs .)"
TRIGGER_JSON="$(printf '%s' "$WHATSAPP_TRIGGER_WORD" | jq -Rs .)"

if [ ! -f "$PERSONA_DIR/system.md" ]; then
  cat > "$PERSONA_DIR/system.md" <<'EOF'
You are Talon, a private personal assistant running locally as a Home Assistant add-on.
Be concise, useful, and careful with actions that affect external systems.
Use configured MCP tools only when they are available and appropriate.
EOF
fi

# First-time WhatsApp pairing.
# Baileys stores credentials persistently under /data/talon/baileys-auth.
if [ "$WHATSAPP_ENABLED" = "true" ] && [ ! -f "$WHATSAPP_AUTH_DIR/creds.json" ]; then
  echo "[talon] WhatsApp is enabled but not paired yet."
  echo "[talon] A QR code will be shown below. Scan it in WhatsApp:"
  echo "[talon] Settings > Linked devices > Link a device"
  echo "[talon] Waiting up to 5 minutes for pairing..."
  node /opt/talond/dist/cli/index.js whatsapp-auth --auth-dir "$WHATSAPP_AUTH_DIR" --timeout 300 || {
    echo "[talon] WhatsApp pairing did not complete. The add-on will stop so you can retry from the logs."
    exit 1
  }
fi

cat > "$CONFIG_FILE" <<EOF
storage:
  type: sqlite
  path: /data/talon/state/talond.sqlite

channels:
EOF

CHANNEL_COUNT=0

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  cat >> "$CONFIG_FILE" <<EOF
  - type: telegram
    name: personal-telegram
    enabled: true
    config:
      botToken: ${TELEGRAM_BOT_TOKEN}
      allowedChatIds:
        - $CHAT_ID_JSON
      pollingTimeoutSec: 30
EOF
  CHANNEL_COUNT=$((CHANNEL_COUNT + 1))
fi

if [ "$WHATSAPP_ENABLED" = "true" ]; then
  cat >> "$CONFIG_FILE" <<EOF
  - type: whatsappBaileys
    name: personal-whatsapp
    enabled: true
    config:
      authDir: /data/talon/baileys-auth
      selfChat: $WHATSAPP_SELF_CHAT
      markOnlineOnConnect: false
      allowGroupChats: false
EOF
  if [ -n "$WHATSAPP_TRIGGER_WORD" ]; then
    cat >> "$CONFIG_FILE" <<EOF
      triggerWords:
        - $TRIGGER_JSON
EOF
  fi
  CHANNEL_COUNT=$((CHANNEL_COUNT + 1))
fi

if [ "$CHANNEL_COUNT" -eq 0 ]; then
  cat >> "$CONFIG_FILE" <<'EOF'
  []
EOF
  echo "[talon] No chat channel is configured."
fi

cat >> "$CONFIG_FILE" <<EOF

personas:
  - name: assistant
    model: $MODEL_JSON
    provider: openai-compatible
    systemPromptFile: /data/talon/personas/assistant/system.md
    skills: []
    subagents: []
    capabilities:
      allow:
        - memory.access:*
        - subagent.invoke:*
        - channel.send:*
      requireApproval: []
    maxConcurrent: 2

bindings:
EOF

BINDING_COUNT=0

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  cat >> "$CONFIG_FILE" <<'EOF'
  - persona: assistant
    channel: personal-telegram
    isDefault: true
EOF
  BINDING_COUNT=$((BINDING_COUNT + 1))
fi

if [ "$WHATSAPP_ENABLED" = "true" ]; then
  cat >> "$CONFIG_FILE" <<'EOF'
  - persona: assistant
    channel: personal-whatsapp
    isDefault: true
EOF
  BINDING_COUNT=$((BINDING_COUNT + 1))
fi

if [ "$BINDING_COUNT" -eq 0 ]; then
  cat >> "$CONFIG_FILE" <<'EOF'
  []
EOF
fi

cat >> "$CONFIG_FILE" <<EOF

ipc:
  pollIntervalMs: 500
  daemonSocketDir: /data/talon/state/ipc/daemon

queue:
  maxAttempts: 3
  backoffBaseMs: 1000
  backoffMaxMs: 60000
  concurrencyLimit: 3

scheduler:
  tickIntervalMs: 5000

agentRunner:
  defaultProvider: openai-compatible
  providers:
    openai-compatible:
      enabled: true
      command: node
      contextWindowTokens: 256000
      contextManagement:
        enabled: false
      options:
        baseUrl: https://api.openai.com/v1
        defaultModel: $MODEL_JSON
        providerId: openai
        apiMode: responses
        toolOutputCap: 8000

backgroundAgent:
  enabled: false
  maxConcurrent: 1
  defaultTimeoutMinutes: 30
  defaultProvider: openai-compatible
  providers:
    openai-compatible:
      enabled: false
      command: node
      contextWindowTokens: 256000
      options:
        baseUrl: https://api.openai.com/v1
        defaultModel: $MODEL_JSON
        providerId: openai

auth:
  mode: api_key
  providers:
    openai:
      apiKey: ${OPENAI_API_KEY}
      baseURL: https://api.openai.com/v1

logLevel: info
dataDir: /data/talon/state
EOF

echo "[talon] Starting Talon Home Assistant add-on..."
exec /usr/bin/tini -- node /opt/talond/dist/index.js --config "$CONFIG_FILE"
