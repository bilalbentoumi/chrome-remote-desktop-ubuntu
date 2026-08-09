#!/usr/bin/env bash
# Apply the Chrome Remote Desktop "shared session" patch.
# Makes CRD mirror the user's actual console desktop (gdm-managed GNOME session)
# instead of creating a separate headless virtual session.
set -euo pipefail

CRD_BIN="/opt/google/chrome-remote-desktop/chrome-remote-desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHED="$SCRIPT_DIR/patch/chrome-remote-desktop-patched"
ORIGINAL="$SCRIPT_DIR/patch/chrome-remote-desktop-original"

if [ ! -f "$CRD_BIN" ]; then
  echo "error: $CRD_BIN not found"
  exit 1
fi

if cmp -s "$CRD_BIN" "$PATCHED"; then
  echo "Patch already applied."
  exit 0
fi

if ! cmp -s "$CRD_BIN" "$ORIGINAL"; then
  echo "error: $CRD_BIN differs from both the original and the patched copy."
  echo "It was probably updated by a package upgrade. Regenerate the patch"
  echo "against the new version before applying."
  exit 1
fi

echo "Stopping Chrome Remote Desktop service..."
systemctl stop "chrome-remote-desktop@$(id -un)"

echo "Applying patch..."
sudo cp "$PATCHED" "$CRD_BIN"
sudo chmod 755 "$CRD_BIN"

echo "Restarting Chrome Remote Desktop service..."
systemctl start "chrome-remote-desktop@$(id -un)"

echo "Done. The remote session now mirrors the console desktop."
