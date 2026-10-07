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
CONFIG_FILE="$CONFIG_DIR/talond.yaml"

mkdir -p "$CONFIG_DIR" "$STATE_DIR" "$PERSONA_DIR" "$SKILLS_DIR" "$SUBAGENTS_DIR" "$USERDATA_DIR"

if [ ! -f "$OPTIONS" ]; then
  echo "[talon] Home Assistant options file not found: $OPTIONS"
  exit 1
fi

OPENAI_API_KEY="$(jq -r '.openai_api_key // ""' "$OPTIONS")"
OPENAI_MODEL="$(jq -r '.openai_model // "gpt-5.4"' "$OPTIONS")"
TELEGRAM_BOT_TOKEN="$(jq -r '.telegram_bot_token // ""' "$OPTIONS")"
TELEGRAM_CHAT_ID="$(jq -r '.telegram_chat_id // ""' "$OPTIONS")"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "[talon] openai_api_key is empty. Set it in the add-on Configuration tab."
  exit 1
fi

export OPENAI_API_KEY
export TELEGRAM_BOT_TOKEN

MODEL_JSON="$(printf '%s' "$OPENAI_MODEL" | jq -Rs .)"
CHAT_ID_JSON="$(printf '%s' "$TELEGRAM_CHAT_ID" | jq -Rs .)"

if [ ! -f "$PERSONA_DIR/system.md" ]; then
  cat > "$PERSONA_DIR/system.md" <<'EOF'
You are Talon, a private personal assistant running locally as a Home Assistant add-on.
Be concise, useful, and careful with actions that affect external systems.
Use configured MCP tools only when they are available and appropriate.
EOF
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[talon] No persistent config found; bootstrapping $CONFIG_FILE from Home Assistant options."
  cat > "$CONFIG_FILE" <<EOF
storage:
  type: sqlite
  path: /data/talon/state/talond.sqlite

channels:
EOF

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
else
  cat >> "$CONFIG_FILE" <<'EOF'
  []
EOF
  echo "[talon] Telegram is not configured; Talon will start without a chat channel."
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
      requireApproval: []
    maxConcurrent: 2

bindings:
EOF

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  cat >> "$CONFIG_FILE" <<'EOF'
  - persona: assistant
    channel: personal-telegram
    isDefault: true
EOF
else
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

  echo "[talon] Bootstrap complete. Future starts will preserve this Talon config."
else
  echo "[talon] Using persistent Talon config: $CONFIG_FILE (not regenerated)."
fi

cd "$CONFIG_DIR"
export PATH="/opt/talond/node_modules/.bin:$PATH"
echo "[talon] Starting Talon Home Assistant add-on..."
exec /usr/bin/tini -- node /opt/talond/dist/index.js --config "$CONFIG_FILE"
