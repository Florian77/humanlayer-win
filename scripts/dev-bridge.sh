#!/usr/bin/env bash
set -euo pipefail

# Starts the remote bridge with debug logging enabled.
# Uses defaults unless overridden via env:
#   HUMANLAYER_REMOTE_BRIDGE_PORT (default 17650)
#   HUMANLAYER_REMOTE_BRIDGE_DEBUG=1 (enable request logging)
#   HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN (optional path to hld-dev/hld)
#   HUMANLAYER_REMOTE_BRIDGE_DAEMON_PORT (optional daemon port hint)
#   HUMANLAYER_BRIDGE_BRANCH (optional branch/version id)
#   HUMANLAYER_REMOTE_BRIDGE_AUTOSTART (default 1; set to 0 to disable daemon autostart)
#   HUMANLAYER_REMOTE_PORT / HUMANLAYER_REMOTE_SOCKET / HUMANLAYER_REMOTE_DB (for autostart settings)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export HUMANLAYER_REMOTE_BRIDGE_DEBUG="${HUMANLAYER_REMOTE_BRIDGE_DEBUG:-1}"
export HUMANLAYER_REMOTE_BRIDGE_PORT="${HUMANLAYER_REMOTE_BRIDGE_PORT:-17650}"
export HUMANLAYER_REMOTE_BRIDGE_AUTOSTART="${HUMANLAYER_REMOTE_BRIDGE_AUTOSTART:-1}"

cd "$ROOT_DIR/humanlayer-wui"
echo "Starting remote bridge on port ${HUMANLAYER_REMOTE_BRIDGE_PORT} (debug=${HUMANLAYER_REMOTE_BRIDGE_DEBUG}, autostart=${HUMANLAYER_REMOTE_BRIDGE_AUTOSTART})..."
bun run remote-bridge
