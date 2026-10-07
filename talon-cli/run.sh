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
    TALON_WORKSPACE="/share/talon"
    ;;
  *[!A-Za-z0-9._-]*|.*|*..*)
    echo "[talon-cli] Invalid instance name: '$INSTANCE'"
    echo "[talon-cli] Use only letters, numbers, dot, underscore and dash; '..' is not allowed."
    exit 1
    ;;
  *)
    TALON_WORKSPACE="/share/talon-instances/$INSTANCE"
    ;;
esac

mkdir -p \
  "$TALON_WORKSPACE/skills" \
  "$TALON_WORKSPACE/personas" \
  "$TALON_WORKSPACE/subagents" \
  "$TALON_WORKSPACE/userdata" \
  "$TALON_WORKSPACE/data/ipc/daemon"

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
