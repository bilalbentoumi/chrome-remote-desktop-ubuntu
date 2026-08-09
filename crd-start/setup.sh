#!/usr/bin/env bash
# Install the post-login Chrome Remote Desktop start for the shared-session
# setup.
#
# The boot-time service `chrome-remote-desktop@<user>` is disabled because it
# starts before the console X session exists (blocking GDM login in the
# process). Instead a user-level unit is enabled on `graphical-session.target`,
# so CRD starts right after the user logs into the GNOME console session and
# attaches to the real console display.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_TEMPLATE="$SCRIPT_DIR/chrome-remote-desktop-console.service"
UNIT_DEST="$HOME/.config/systemd/user/chrome-remote-desktop-console.service"

if [ ! -x /opt/google/chrome-remote-desktop/chrome-remote-desktop ]; then
  echo "error: chrome-remote-desktop is not installed" >&2
  exit 1
fi

HOST_HASH=$(python3 -c 'import hashlib, socket; print(hashlib.md5(socket.gethostname().encode()).hexdigest())')
echo "Host config hash: $HOST_HASH"

echo "Installing unit -> $UNIT_DEST"
mkdir -p "$(dirname "$UNIT_DEST")"
sed "s/HOST_HASH/$HOST_HASH/" "$UNIT_TEMPLATE" > "$UNIT_DEST"

echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "Enabling unit (starts with graphical-session.target)..."
systemctl --user enable chrome-remote-desktop-console.service

if systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
  echo "Graphical session already active; starting the unit now..."
  systemctl --user start chrome-remote-desktop-console.service
fi

echo "Disabling the boot-time CRD service (it blocks GDM login)..."
sudo systemctl disable --now "chrome-remote-desktop@$(id -un)" 2>/dev/null || \
  echo "note: boot-time service was already disabled."

echo "Done. CRD will start automatically after graphical login."
