# Nautilus (GNOME Files) activation fix

When Chrome Remote Desktop runs in shared-session mode, DBus-activated apps
such as GNOME Files (Nautilus) can fail to open with `Failed to open display`.

## Why

GNOME Shell starts Nautilus at login and it keeps running, so the FileManager1
interface works. If that instance exits, the session dbus-daemon (`--systemd-activation`)
spawns a fresh Nautilus with a minimal environment that has no `DISPLAY` (and may
inherit a stale `XAUTHORITY` left over from a CRD virtual session), so the new
instance dies with "Failed to open display".

## The fix

Route Nautilus activation through `systemd --user`, which has the correct
console `DISPLAY`/`XAUTHORITY`, via a wrapper that detects the display at
startup (same logic as the CRD shared-session patch):

- `nautilus-console` — wrapper that probes displays `:0..:15` with
  `xdpyinfo` using `/run/user/<uid>/gdm/Xauthority`, then `exec`s Nautilus.
- `org.gnome.Nautilus.service` — systemd user unit (`Type=dbus`,
  `BusName=org.gnome.Nautilus`) installed to `~/.config/systemd/user/`.
- `org.gnome.Nautilus.dbus-service` — user DBus service override (takes
  precedence over `/usr/share/dbus-1/services/`) that adds
  `SystemdService=org.gnome.Nautilus.service`, installed to
  `~/.local/share/dbus-1/services/`.
- `org.freedesktop.FileManager1.dbus-service` — user DBus override so the
  generic file-manager interface (`ShowItems`/`ShowFolders`) is served by
  Nautilus instead of a leftover Thunar daemon (which ships its own competing
  service file with `SystemdService=thunar.service`).

`setup.sh` also stops `thunar.service` so Nautilus owns `FileManager1`.

## Usage

```bash
cd ~/Workspace/chrome-remote-desktop-shared-session/nautilus-fix
./setup.sh
```

Run it again after a reboot if the leftover Thunar returns, or disable it:
`systemctl --user mask thunar.service`.

## Notes

- The wrapper detects the console display dynamically, so it survives
  display-number changes across reboots.
- Other GTK apps activated via DBus may hit the same issue; the same pattern
  (wrapper + systemd unit + `SystemdService` override) can be applied to them.
