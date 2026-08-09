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

echo "Stopping Chrome Remote Desktop service..."
systemctl stop "chrome-remote-desktop@$(id -un)"

echo "Restoring original script..."
sudo cp "$ORIGINAL" "$CRD_BIN"
sudo chmod 755 "$CRD_BIN"

echo "Restarting Chrome Remote Desktop service..."
systemctl start "chrome-remote-desktop@$(id -un)"

echo "Done. CRD is back to its default headless virtual session behaviour."
