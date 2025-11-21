#!/usr/bin/env bash
set -euo pipefail

# Creates/refreshes a symlink under dev-logs pointing to the full WUI logs folder.
# Target: ~/.humanlayer/logs/

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_LOGS_DIR="${ROOT_DIR}/dev-logs"

target="$HOME/.humanlayer/logs"
link="${DEV_LOGS_DIR}/wui-logs"

mkdir -p "$DEV_LOGS_DIR"
if [[ -d "$target" ]]; then
  ln -sfn "$target" "$link"
  echo "Linked ${link} -> ${target}"
else
  echo "Log dir not found at ${target} (start WUI once to create logs)"
fi
