#!/usr/bin/env bash
# Stop and disable the post-login Chrome Remote Desktop unit.
# CRD will no longer start with the graphical session.
set -euo pipefail

echo "Stopping and disabling user unit..."
systemctl --user disable --now chrome-remote-desktop-console.service 2>/dev/null || true

echo "Done. CRD will no longer start with the graphical session."
