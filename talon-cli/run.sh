#!/bin/sh
set -eu

SHARED_BASE="/share/talon"

mkdir -p "$SHARED_BASE/skills" "$SHARED_BASE/personas" "$SHARED_BASE/subagents" "$SHARED_BASE/userdata" "$SHARED_BASE/data/ipc/daemon"
cd "$SHARED_BASE"

export TALOND_CONFIG_PATH="$SHARED_BASE/talond.yaml"
export PATH="/usr/local/bin:/opt/talond/node_modules/.bin:$PATH"

cat >/root/.bashrc <<'EOF'
cd /share/talon
export TALOND_CONFIG_PATH=/share/talon/talond.yaml
export PATH=/usr/local/bin:/opt/talond/node_modules/.bin:$PATH
echo
echo "Talon CLI"
echo "Workspace: /share/talon"
echo "Try: talonctl list-personas"
echo "     talonctl list-skills"
echo "     talonctl --help"
echo
EOF

echo "[talon-cli] Starting Home Assistant Ingress terminal for /share/talon"
exec /usr/local/bin/ttyd -W -p 7681 /bin/bash -l
