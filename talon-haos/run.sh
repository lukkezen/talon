#!/bin/sh
set -eu

OPTIONS="/data/options.json"
STATE_DIR="/data/talon/state"
CONFIG_ROOT="/config"
APP_CONFIG_MARKER="$CONFIG_ROOT/.talon-daemon-app-config"

if [ ! -f "$OPTIONS" ]; then
  echo "[talon] Home Assistant options file not found: $OPTIONS"
  exit 1
fi

INSTANCE="$(jq -r '.instance // ""' "$OPTIONS" | xargs)"

case "$INSTANCE" in
  "")
    INSTANCE_DIR="default"
    ;;
  *[!A-Za-z0-9._-]*|.*|*..*)
    echo "[talon] Invalid instance name: '$INSTANCE'"
    echo "[talon] Use only letters, numbers, dot, underscore and dash; '..' is not allowed."
    exit 1
    ;;
  *)
    INSTANCE_DIR="$INSTANCE"
    ;;
esac

WORKSPACE="$CONFIG_ROOT/instances/$INSTANCE_DIR"
CONFIG_FILE="$WORKSPACE/talond.yaml"
PERSONA_DIR="$WORKSPACE/personas/assistant"
SHARED_IPC_DIR="$WORKSPACE/data/ipc/daemon"
PRIVATE_IPC_DIR="$STATE_DIR/ipc/daemon"
BOOTSTRAP_MARKER="$WORKSPACE/.bootstrapped-v0.6"

: > "$APP_CONFIG_MARKER"

mkdir -p "$STATE_DIR/ipc" "$WORKSPACE/skills" "$WORKSPACE/personas" "$WORKSPACE/subagents" "$WORKSPACE/userdata" "$SHARED_IPC_DIR"

if [ -L "$PRIVATE_IPC_DIR" ]; then
  rm -f "$PRIVATE_IPC_DIR"
elif [ -e "$PRIVATE_IPC_DIR" ]; then
  rm -rf "$PRIVATE_IPC_DIR"
fi
ln -s "$SHARED_IPC_DIR" "$PRIVATE_IPC_DIR"
echo "[talon] Shared CLI IPC: $PRIVATE_IPC_DIR -> $SHARED_IPC_DIR"

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
export TALON_INSTANCE="$INSTANCE"
export TALON_WORKSPACE="$WORKSPACE"
export TALOND_CONFIG_PATH="$CONFIG_FILE"

MODEL_JSON="$(printf '%s' "$OPENAI_MODEL" | jq -Rs .)"
CHAT_ID_JSON="$(printf '%s' "$TELEGRAM_CHAT_ID" | jq -Rs .)"

mkdir -p "$PERSONA_DIR"
if [ ! -f "$PERSONA_DIR/system.md" ]; then
  cat > "$PERSONA_DIR/system.md" <<'EOF'
You are Talon, a private personal assistant running locally as a Home Assistant add-on.
Be concise, useful, and careful with actions that affect external systems.
Use configured MCP tools only when they are available and appropriate.
EOF
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[talon] No isolated config found for instance ${INSTANCE:-default}; bootstrapping $CONFIG_FILE."
  echo "[talon] If this instance previously lived under /share, start Talon CLI 0.3.0 once to migrate it."
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
      botToken: \${TELEGRAM_BOT_TOKEN}
      allowedChatIds:
        - $CHAT_ID_JSON
      pollingTimeoutSec: 30
EOF
  else
    cat >> "$CONFIG_FILE" <<'EOF'
  []
EOF
  fi

  cat >> "$CONFIG_FILE" <<EOF

personas:
  - name: assistant
    model: $MODEL_JSON
    provider: openai-compatible
    systemPromptFile: $WORKSPACE/personas/assistant/system.md
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
  daemonSocketDir: $SHARED_IPC_DIR

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
      apiKey: \${OPENAI_API_KEY}
      baseURL: https://api.openai.com/v1

logLevel: info
dataDir: /data/talon/state
EOF
  : > "$BOOTSTRAP_MARKER"
  echo "[talon] Bootstrap complete."
else
  echo "[talon] Using isolated Talon workspace: $WORKSPACE"
fi

cd "$WORKSPACE"
export PATH="/opt/talond/node_modules/.bin:$PATH"
echo "[talon] Instance: ${INSTANCE:-default}"
echo "[talon] Workspace: $WORKSPACE"
echo "[talon] Direct Home Assistant /share access: disabled"
echo "[talon] Starting Talon Home Assistant add-on..."
exec /usr/bin/tini -- node /opt/talond/dist/index.js --config "$CONFIG_FILE"
