#!/usr/bin/env bash
set -euo pipefail

# Starts the daemon via the remote bridge /invoke API with explicit socket/port.
# Override via env if needed:
#   HUMANLAYER_REMOTE_BRIDGE_PORT (default 17650)
#   HUMANLAYER_REMOTE_SOCKET (default ~/.humanlayer/daemon-remote.sock)
#   HUMANLAYER_REMOTE_DB (default ~/.humanlayer/daemon-remote.db)
#   HUMANLAYER_REMOTE_PORT (default 7777)
#   HUMANLAYER_BRIDGE_BRANCH (default remote-bridge)

BRIDGE_PORT="${HUMANLAYER_REMOTE_BRIDGE_PORT:-17650}"
SOCKET_PATH="${HUMANLAYER_REMOTE_SOCKET:-$HOME/.humanlayer/daemon-remote.sock}"
DB_PATH="${HUMANLAYER_REMOTE_DB:-$HOME/.humanlayer/daemon-remote.db}"
DAEMON_PORT="${HUMANLAYER_REMOTE_PORT:-7777}"
BRANCH="${HUMANLAYER_BRIDGE_BRANCH:-remote-bridge}"

payload=$(cat <<JSON
{
  "cmd": "start_daemon",
  "args": {
    "port": ${DAEMON_PORT},
    "socketPath": "${SOCKET_PATH}",
    "databasePath": "${DB_PATH}",
    "branchId": "${BRANCH}"
  }
}
JSON
)

echo "Starting daemon via bridge on port ${DAEMON_PORT}, socket ${SOCKET_PATH}, branch ${BRANCH}..."
curl -s -X POST "http://localhost:${BRIDGE_PORT}/invoke" \
  -H 'Content-Type: application/json' \
  -d "${payload}"
echo
