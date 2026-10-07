#!/bin/sh
set -eu

OPTIONS="/data/options.json"

read_instance() {
  if [ ! -f "$OPTIONS" ]; then
    printf '%s' ""
    return
  fi
  node -e '
    const fs = require("fs");
    try {
      const o = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      process.stdout.write(String(o.instance ?? "").trim());
    } catch {
      process.stdout.write("");
    }
  ' "$OPTIONS"
 }

INSTANCE="$(read_instance)"

case "$INSTANCE" in
  "")
    INSTANCE_DIR="default"
    LEGACY_WORKSPACE="/share/talon"
    ;;
  *[!A-Za-z0-9._-]*|.*|*..*)
    echo "[talon-cli] Invalid instance name: '$INSTANCE'"
    echo "[talon-cli] Use only letters, numbers, dot, underscore and dash; '..' is not allowed."
    exit 1
    ;;
  *)
    INSTANCE_DIR="$INSTANCE"
    LEGACY_WORKSPACE="/share/talon-instances/$INSTANCE"
    ;;
esac

DAEMON_CONFIG_ROOTS="$(find /addon_configs -mindepth 1 -maxdepth 1 -type d -name '*_talon' 2>/dev/null || true)"
DAEMON_CONFIG_ROOT="$(printf '%s\n' "$DAEMON_CONFIG_ROOTS" | sed '/^$/d' | head -n 1)"
DAEMON_CONFIG_COUNT="$(printf '%s\n' "$DAEMON_CONFIG_ROOTS" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$DAEMON_CONFIG_COUNT" -eq 0 ] || [ -z "$DAEMON_CONFIG_ROOT" ]; then
  echo "[talon-cli] Could not find the Talon daemon app_config under /addon_configs."
  echo "[talon-cli] Install/start Talon 0.6.0 once, then restart this CLI."
  exit 1
fi
if [ "$DAEMON_CONFIG_COUNT" -gt 1 ]; then
  echo "[talon-cli] Multiple *_talon app_config directories found:"
  printf '%s\n' "$DAEMON_CONFIG_ROOTS"
  echo "[talon-cli] Refusing to guess which Talon daemon to manage."
  exit 1
fi

if [ -L /config ]; then
  rm -f /config
elif [ -e /config ]; then
  rm -rf /config
fi
ln -s "$DAEMON_CONFIG_ROOT" /config

TALON_WORKSPACE="/config/instances/$INSTANCE_DIR"
BOOTSTRAP_MARKER="$TALON_WORKSPACE/.bootstrapped-v0.6"

mkdir -p "$TALON_WORKSPACE/skills" "$TALON_WORKSPACE/personas" "$TALON_WORKSPACE/subagents" "$TALON_WORKSPACE/userdata" "$TALON_WORKSPACE/data/ipc/daemon"

if [ -f "$LEGACY_WORKSPACE/talond.yaml" ] && { [ ! -f "$TALON_WORKSPACE/talond.yaml" ] || [ -f "$BOOTSTRAP_MARKER" ]; }; then
  echo "[talon-cli] Migrating legacy workspace: $LEGACY_WORKSPACE -> $TALON_WORKSPACE"
  rm -rf "$TALON_WORKSPACE"
  mkdir -p "$TALON_WORKSPACE"
  cp -a "$LEGACY_WORKSPACE/." "$TALON_WORKSPACE/"

  sed -i -e "s#$LEGACY_WORKSPACE#$TALON_WORKSPACE#g" -e "s#/share/talon-instances/$INSTANCE#$TALON_WORKSPACE#g" -e "s#/share/talon#$TALON_WORKSPACE#g" "$TALON_WORKSPACE/talond.yaml"

  rm -f "$TALON_WORKSPACE/.bootstrapped-v0.6"
  echo "[talon-cli] Migration complete. Legacy /share copy was left intact as a fallback."
  echo "[talon-cli] Restart Talon after this migration."
fi

export TALON_WORKSPACE
export TALOND_CONFIG_PATH="$TALON_WORKSPACE/talond.yaml"
export PATH="/usr/local/bin:/opt/talond/node_modules/.bin:$PATH"

cat >/root/.bashrc <<EOF
cd "$TALON_WORKSPACE"
export TALON_WORKSPACE="$TALON_WORKSPACE"
export TALOND_CONFIG_PATH="$TALON_WORKSPACE/talond.yaml"
export PATH="/usr/local/bin:/opt/talond/node_modules/.bin:\$PATH"
echo
echo "Talon CLI"
echo "Instance: ${INSTANCE:-default}"
echo "Workspace: $TALON_WORKSPACE"
echo "Daemon config root: $DAEMON_CONFIG_ROOT"
if [ ! -f "$TALON_WORKSPACE/talond.yaml" ]; then
  echo "Warning: talond.yaml does not exist in this workspace yet."
fi
echo "Try: talonctl list-personas"
echo "     talonctl list-skills"
echo "     talonctl --help"
echo
EOF

cat >/root/.bash_profile <<'EOF'
[ -f /root/.bashrc ] && . /root/.bashrc
EOF

echo "[talon-cli] Instance: ${INSTANCE:-default}"
echo "[talon-cli] Workspace: $TALON_WORKSPACE"
echo "[talon-cli] Starting Home Assistant Ingress terminal..."
exec /usr/local/bin/ttyd -W -p 7681 /bin/bash -l
