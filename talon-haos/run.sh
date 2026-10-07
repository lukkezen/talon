#!/bin/sh
set -eu

OPTIONS="/data/options.json"
WORKSPACE="/talon"
CONFIG_FILE="$WORKSPACE/talond.yaml"
STATE_DIR="/data/talon/state"
LEGACY_PRIVATE="/data/talon"
LEGACY_SHARED="/ha-share/talon"
PERSONA_DIR="$WORKSPACE/personas/assistant"
SOURCES_DIR="$WORKSPACE/ha-readonly"

mkdir -p "$WORKSPACE" "$STATE_DIR" "$WORKSPACE/skills" "$WORKSPACE/personas" "$WORKSPACE/subagents" "$WORKSPACE/userdata" "$WORKSPACE/data/ipc/daemon" "$SOURCES_DIR"
printf '%s\n' "talon-haos-workspace-v1" > "$WORKSPACE/.talon-haos-workspace"

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

migrate_workspace() {
  source_dir="$1"
  source_config="$2"

  echo "[talon] Migrating Talon workspace from $source_dir to $WORKSPACE"
  cp "$source_config" "$CONFIG_FILE"

  for dir in personas skills subagents userdata; do
    if [ -d "$source_dir/$dir" ]; then
      cp -a "$source_dir/$dir/." "$WORKSPACE/$dir/" 2>/dev/null || true
    fi
  done

  sed -i \
    -e 's#/share/talon#/talon#g' \
    -e 's#/data/talon/personas#/talon/personas#g' \
    -e 's#/data/talon/skills#/talon/skills#g' \
    -e 's#/data/talon/subagents#/talon/subagents#g' \
    -e 's#/data/talon/userdata#/talon/userdata#g' \
    -e 's#/data/talon/state/ipc/daemon#/talon/data/ipc/daemon#g' \
    "$CONFIG_FILE"

  # Never keep bootstrap secrets in the persistent config file.
  sed -i \
    -e 's#^[[:space:]]*botToken:.*#      botToken: ${TELEGRAM_BOT_TOKEN}#' \
    -e 's#^[[:space:]]*apiKey:.*#      apiKey: ${OPENAI_API_KEY}#' \
    "$CONFIG_FILE"

  echo "[talon] Migration complete. Original files were left untouched as a fallback."
}

# Upgrade path from v0.4.x (/share/talon) or older v0.3.x (/data/talon).
if [ ! -f "$CONFIG_FILE" ]; then
  if [ -f "$LEGACY_SHARED/talond.yaml" ]; then
    migrate_workspace "$LEGACY_SHARED" "$LEGACY_SHARED/talond.yaml"
  elif [ -f "$LEGACY_PRIVATE/config/talond.yaml" ]; then
    migrate_workspace "$LEGACY_PRIVATE" "$LEGACY_PRIVATE/config/talond.yaml"
  fi
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
    systemPromptFile: /talon/personas/assistant/system.md
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
  daemonSocketDir: /talon/data/ipc/daemon

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
  echo "[talon] Using persistent Talon workspace: $WORKSPACE"
fi

# Build a managed set of aliases to selected read-only Home Assistant folders.
# The underlying /ha-share and /ha-media mounts are read-only at Supervisor level.
find "$SOURCES_DIR" -mindepth 1 -maxdepth 1 -type l -delete 2>/dev/null || true
rm -f "$SOURCES_DIR/sources.json"
printf '%s\n' '[]' > "$SOURCES_DIR/sources.json"

SOURCE_COUNT="$(jq '.readonly_sources // [] | length' "$OPTIONS")"
i=0
while [ "$i" -lt "$SOURCE_COUNT" ]; do
  NAME="$(jq -r ".readonly_sources[$i].name // \"\"" "$OPTIONS")"
  ROOT="$(jq -r ".readonly_sources[$i].root // \"\"" "$OPTIONS")"
  REL_PATH="$(jq -r ".readonly_sources[$i].path // \"\"" "$OPTIONS")"

  case "$NAME" in
    ""|*[!A-Za-z0-9._-]*)
      echo "[talon] Ignoring read-only source with invalid name: $NAME"
      i=$((i + 1))
      continue
      ;;
  esac

  case "$REL_PATH" in
    ""|/*|*".."*)
      echo "[talon] Ignoring read-only source '$NAME': path must be relative and may not contain '..'."
      i=$((i + 1))
      continue
      ;;
  esac

  case "$ROOT" in
    share) SOURCE_BASE="/ha-share" ;;
    media) SOURCE_BASE="/ha-media" ;;
    *)
      echo "[talon] Ignoring read-only source '$NAME': root must be share or media."
      i=$((i + 1))
      continue
      ;;
  esac

  SOURCE_PATH="$SOURCE_BASE/$REL_PATH"
  if [ ! -e "$SOURCE_PATH" ]; then
    echo "[talon] Read-only source '$NAME' does not exist: $SOURCE_PATH"
    i=$((i + 1))
    continue
  fi

  ln -s "$SOURCE_PATH" "$SOURCES_DIR/$NAME"
  TMP_JSON="$SOURCES_DIR/sources.json.tmp"
  jq --arg name "$NAME" --arg root "$ROOT" --arg path "$REL_PATH" --arg alias "$SOURCES_DIR/$NAME" \
    '. + [{name:$name, root:$root, path:$path, alias:$alias, readOnly:true}]' \
    "$SOURCES_DIR/sources.json" > "$TMP_JSON"
  mv "$TMP_JSON" "$SOURCES_DIR/sources.json"
  echo "[talon] Read-only source enabled: $NAME -> $SOURCE_PATH"
  i=$((i + 1))
done

cd "$WORKSPACE"
export PATH="/opt/talond/node_modules/.bin:$PATH"
echo "[talon] Starting Talon Home Assistant add-on..."
exec /usr/bin/tini -- node /opt/talond/dist/index.js --config "$CONFIG_FILE"
