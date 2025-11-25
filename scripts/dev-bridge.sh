#!/usr/bin/env bash
set -euo pipefail

# Starts the remote bridge with debug logging enabled.
#
# ============================================================================
# BRIDGE ENV VARS:
# ============================================================================
#   HUMANLAYER_REMOTE_BRIDGE_PORT      - Bridge HTTP port (default: 17650)
#   HUMANLAYER_REMOTE_BRIDGE_DEBUG     - Enable request logging (default: 1)
#   HUMANLAYER_REMOTE_BRIDGE_AUTOSTART - Auto-start daemon (default: 1, set 0 to disable)
#   HUMANLAYER_REMOTE_BRIDGE_DAEMON_BIN - Path to hld-dev/hld binary (optional)
#   HUMANLAYER_REMOTE_BRIDGE_LOG_BASE  - Base directory for logs (default: ~/.humanlayer/logs/remote-bridge)
#   HUMANLAYER_REMOTE_BRIDGE_SPLIT_LOGS - Split daemon logs by level/type (default: 0)
#                                         When enabled, creates separate files:
#                                         - daemon-remote-gin-*.log    (HTTP request logs [GIN])
#                                         - daemon-remote-debug-*.log  (DEBUG level)
#                                         - daemon-remote-info-*.log   (INFO level)
#                                         - daemon-remote-warn-*.log   (WARN level)
#                                         - daemon-remote-error-*.log  (ERROR level)
#                                         - daemon-remote-other-*.log  (unmatched lines)
#
# ============================================================================
# DAEMON ENV VARS (passed through to hld):
# ============================================================================
#   HUMANLAYER_REMOTE_PORT   - Daemon HTTP port (default: 7777)
#   HUMANLAYER_REMOTE_SOCKET - Daemon socket path (default: ~/.humanlayer/daemon-remote.sock)
#   HUMANLAYER_REMOTE_DB     - Daemon database path (default: ~/.humanlayer/daemon-remote.db)
#   HUMANLAYER_BRIDGE_BRANCH - Branch/version identifier (default: remote-bridge)
#
#   HUMANLAYER_LOG_LEVEL     - Daemon log level: debug, info, warn, error (default: debug)
#   HUMANLAYER_DEBUG         - Enable debug mode in daemon (default: true)
#   GIN_MODE                 - GIN framework mode: debug, release, test (default: debug)
#                              Set to "release" to reduce GIN log verbosity
#
# ============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Bridge settings
export HUMANLAYER_REMOTE_BRIDGE_PORT="${HUMANLAYER_REMOTE_BRIDGE_PORT:-17650}"
export HUMANLAYER_REMOTE_BRIDGE_DEBUG="${HUMANLAYER_REMOTE_BRIDGE_DEBUG:-1}"
export HUMANLAYER_REMOTE_BRIDGE_AUTOSTART="${HUMANLAYER_REMOTE_BRIDGE_AUTOSTART:-1}"
export HUMANLAYER_REMOTE_BRIDGE_SPLIT_LOGS="${HUMANLAYER_REMOTE_BRIDGE_SPLIT_LOGS:-1}"

# Daemon settings (uncomment/modify as needed)
# export HUMANLAYER_LOG_LEVEL="debug"      # debug | info | warn | error
# export HUMANLAYER_DEBUG="true"           # true | false
# export GIN_MODE="debug"                  # debug | release | test

cd "$ROOT_DIR/humanlayer-wui"
echo "Starting remote bridge on port ${HUMANLAYER_REMOTE_BRIDGE_PORT}"
echo "  debug=${HUMANLAYER_REMOTE_BRIDGE_DEBUG}"
echo "  autostart=${HUMANLAYER_REMOTE_BRIDGE_AUTOSTART}"
echo "  split_logs=${HUMANLAYER_REMOTE_BRIDGE_SPLIT_LOGS}"
bun run remote-bridge
