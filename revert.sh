#!/usr/bin/env bash
# Revert the Chrome Remote Desktop "shared session" patch.
# Restores the original package script, so CRD returns to running a separate
# headless virtual session.
set -euo pipefail

CRD_BIN="/opt/google/chrome-remote-desktop/chrome-remote-desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL="$SCRIPT_DIR/patch/chrome-remote-desktop-original"

if [ ! -f "$CRD_BIN" ]; then
  echo "error: $CRD_BIN not found"
  exit 1
fi

echo "Stopping and disabling the post-login CRD unit..."
systemctl --user disable --now chrome-remote-desktop-console.service 2>/dev/null || true

echo "Stopping boot-time Chrome Remote Desktop service..."
sudo systemctl stop "chrome-remote-desktop@$(id -un)" 2>/dev/null || true

echo "Restoring original script..."
sudo cp "$ORIGINAL" "$CRD_BIN"
sudo chmod 755 "$CRD_BIN"

echo "Re-enabling boot-time Chrome Remote Desktop service (stock behaviour)..."
sudo systemctl enable "chrome-remote-desktop@$(id -un)" 2>/dev/null || true

echo "Done. CRD is back to its default headless virtual session behaviour."
