#!/bin/sh
set -eu

OPTIONS="/data/options.json"
LEGACY_BASE="/data/talon"
STATE_DIR="$LEGACY_BASE/state"
SHARED_BASE="/share/talon"
CONFIG_FILE="$SHARED_BASE/talond.yaml"
PERSONA_DIR="$SHARED_BASE/personas/assistant"

mkdir -p "$STATE_DIR" "$SHARED_BASE/skills" "$SHARED_BASE/personas" "$SHARED_BASE/subagents" "$SHARED_BASE/userdata" "$SHARED_BASE/data/ipc/daemon"

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
export TALOND_CONFIG_PATH="$CONFIG_FILE"

MODEL_JSON="$(printf '%s' "$OPENAI_MODEL" | jq -Rs .)"
CHAT_ID_JSON="$(printf '%s' "$TELEGRAM_CHAT_ID" | jq -Rs .)"

# One-time migration from the pre-0.4 private add-on layout.
if [ ! -f "$CONFIG_FILE" ] && [ -f "$LEGACY_BASE/config/talond.yaml" ]; then
  echo "[talon] Migrating Talon configuration to shared upstream-style workspace: $SHARED_BASE"
  cp "$LEGACY_BASE/config/talond.yaml" "$CONFIG_FILE"

  for dir in personas skills subagents userdata; do
    if [ -d "$LEGACY_BASE/$dir" ]; then
      cp -a "$LEGACY_BASE/$dir/." "$SHARED_BASE/$dir/" 2>/dev/null || true
    fi
  done

  sed -i     -e 's#/data/talon/personas#/share/talon/personas#g'     -e 's#/data/talon/skills#/share/talon/skills#g'     -e 's#/data/talon/subagents#/share/talon/subagents#g'     -e 's#/data/talon/userdata#/share/talon/userdata#g'     -e 's#/data/talon/state/ipc/daemon#/share/talon/data/ipc/daemon#g'     "$CONFIG_FILE"

  echo "[talon] Migration complete. Legacy /data/talon configuration was left intact as a fallback copy."
fi

mkdir -p "$PERSONA_DIR"
if [ ! -f "$PERSONA_DIR/system.md" ]; then
  cat > "$PERSONA_DIR/system.md" <<'EOF'
You are Talon, a private personal assistant running locally as a Home Assistant add-on.
Be concise, useful, and careful with actions that affect external systems.
Use configured MCP tools only when they are available and appropriate.
EOF
fi

# Fresh install: bootstrap once from Home Assistant options.
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[talon] No Talon config found; bootstrapping $CONFIG_FILE from Home Assistant options."
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
  fi

  cat >> "$CONFIG_FILE" <<EOF

personas:
  - name: assistant
    model: $MODEL_JSON
    provider: openai-compatible
    systemPromptFile: /share/talon/personas/assistant/system.md
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
  daemonSocketDir: /share/talon/data/ipc/daemon

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
  echo "[talon] Bootstrap complete. Future starts preserve $CONFIG_FILE."
else
  echo "[talon] Using persistent Talon workspace: $SHARED_BASE"
fi

cd "$SHARED_BASE"
export PATH="/opt/talond/node_modules/.bin:$PATH"
echo "[talon] Starting Talon Home Assistant add-on..."
exec /usr/bin/tini -- node /opt/talond/dist/index.js --config "$CONFIG_FILE"
