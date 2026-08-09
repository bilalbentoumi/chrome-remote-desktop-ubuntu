#!/usr/bin/env bash
# Install the Nautilus (GNOME Files) activation fix for the CRD shared-session
# setup. Makes DBus-activated apps get a working DISPLAY/XAUTHORITY by routing
# activation through systemd --user with a wrapper that detects the console
# display dynamically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WRAPPER_DEST="$HOME/.local/share/crd-session/nautilus-console"
UNIT_DEST="$HOME/.config/systemd/user/org.gnome.Nautilus.service"
DBUS_DEST="$HOME/.local/share/dbus-1/services/org.gnome.Nautilus.service"
FM1_DEST="$HOME/.local/share/dbus-1/services/org.freedesktop.FileManager1.service"

echo "Installing wrapper -> $WRAPPER_DEST"
mkdir -p "$(dirname "$WRAPPER_DEST")"
install -m 755 "$SCRIPT_DIR/nautilus-console" "$WRAPPER_DEST"

echo "Installing systemd unit -> $UNIT_DEST"
mkdir -p "$(dirname "$UNIT_DEST")"
install -m 644 "$SCRIPT_DIR/org.gnome.Nautilus.service" "$UNIT_DEST"

echo "Installing dbus override -> $DBUS_DEST"
mkdir -p "$(dirname "$DBUS_DEST")"
install -m 644 "$SCRIPT_DIR/org.gnome.Nautilus.dbus-service" "$DBUS_DEST"

echo "Installing FileManager1 override -> $FM1_DEST"
install -m 644 "$SCRIPT_DIR/org.freedesktop.FileManager1.dbus-service" "$FM1_DEST"

echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "Restarting Nautilus service..."
systemctl --user restart org.gnome.Nautilus.service

echo "Stopping leftover Thunar so Nautilus owns FileManager1..."
systemctl --user stop thunar.service 2>/dev/null || true

echo "Reloading session bus so the DBus overrides take effect now..."
systemctl --user reload dbus.service

echo "Done. GNOME Files now launches against the console desktop."
