#!/usr/bin/env bash
set -euo pipefail

# Starts the WUI in dev mode using the remote bridge + shim.
# Defaults can be overridden via env:
#   HUMANLAYER_REMOTE_SOCKET (default ~/.humanlayer/daemon-remote.sock)
#   HUMANLAYER_REMOTE_PORT (default 7777)
#   HUMANLAYER_REMOTE_BRIDGE_PORT (default 17650)
#   VITE_TAURI_BRIDGE_URL (default http://localhost:${BRIDGE_PORT})
#   VITE_REMOTE_TAURI_SHIM (default 1)
#   HUMANLAYER_WUI_AUTOLAUNCH_DAEMON (forced false here)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_PORT="${HUMANLAYER_REMOTE_BRIDGE_PORT:-17650}"
SOCKET_PATH="${HUMANLAYER_REMOTE_SOCKET:-$HOME/.humanlayer/daemon-remote.sock}"
DAEMON_PORT="${HUMANLAYER_REMOTE_PORT:-7777}"

export HUMANLAYER_WUI_AUTOLAUNCH_DAEMON=false
export HUMANLAYER_DAEMON_SOCKET="$SOCKET_PATH"
export VITE_HUMANLAYER_DAEMON_URL="${VITE_HUMANLAYER_DAEMON_URL:-http://localhost:${DAEMON_PORT}}"
export VITE_REMOTE_TAURI_SHIM="${VITE_REMOTE_TAURI_SHIM:-1}"
export VITE_TAURI_BRIDGE_URL="${VITE_TAURI_BRIDGE_URL:-http://localhost:${BRIDGE_PORT}}"

echo "Starting WUI with:"
echo "  HUMANLAYER_DAEMON_SOCKET=${HUMANLAYER_DAEMON_SOCKET}"
echo "  VITE_HUMANLAYER_DAEMON_URL=${VITE_HUMANLAYER_DAEMON_URL}"
echo "  VITE_REMOTE_TAURI_SHIM=${VITE_REMOTE_TAURI_SHIM}"
echo "  VITE_TAURI_BRIDGE_URL=${VITE_TAURI_BRIDGE_URL}"

cd "$ROOT_DIR/humanlayer-wui"
bun run tauri dev
