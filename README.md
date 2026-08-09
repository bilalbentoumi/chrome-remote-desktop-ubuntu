# chrome-remote-desktop-shared-session

Makes Chrome Remote Desktop mirror the user's **actual console desktop**
(the gdm-managed GNOME session) instead of creating a separate headless
virtual X session.

Tested against `chrome-remote-desktop` version `152.0.7977.9` on Ubuntu 24.04.

## Why

By default CRD on Linux launches its own virtual X server (display `:20`) and a
fresh desktop session. That is fine on headless machines, but on a machine with
a console GUI it means remote users see a *different* desktop. Worse, GNOME
refuses to run two sessions for the same user (`Session manager already
running`), so the default CRD GNOME session crashes immediately.

This patch instead points the CRD host process at the already-running console
X display owned by the logged-in user, so a remote connection shows and
controls the same desktop that is on the screen.

## Patch content

See `patch/crd-shared-session.patch` (unified diff). Three changes to
`/opt/google/chrome-remote-desktop/chrome-remote-desktop`:

1. `launch_session()` (base class): skip `_launch_server()`, the pre-session
   script, and `launch_desktop_session()` — do not create a new X server or
   desktop.
2. `XDesktop.launch_session()`: set `DISPLAY` and `XAUTHORITY` on the child
   environment so the host captures the console session.
3. Added `_get_console_display()`: probes displays `:0`..`:15` with
   `xdpyinfo` using `/run/user/<uid>/gdm/Xauthority` and returns the first that
   responds (falls back to `:1`).

## Files

- `patch/crd-shared-session.patch` — unified diff (apply with
  `patch -p1` inside the package dir, or use the helper scripts).
- `patch/chrome-remote-desktop-original` — pristine packaged script.
- `patch/chrome-remote-desktop-patched` — ready-to-install patched script.
- `crd-start/` — post-login CRD start (user systemd unit + setup/disable scripts).
- `nautilus-fix/` — Nautilus (GNOME Files) DBus activation fix.
- `apply.sh` — copies the patched script into place and installs `crd-start/`.
- `revert.sh` — restores the original script and re-enables the boot service.

## Usage

```bash
cd ~/Workspace/chrome-remote-desktop-shared-session
./apply.sh     # or
./revert.sh
```

After `apply.sh`, reboot or just log into the GNOME console session: CRD
starts automatically once `graphical-session.target` is reached.

## How CRD is started after the fix

The packaged boot service `chrome-remote-desktop@<user>` is **disabled**,
because it starts before the console X session exists — the CRD PAM session
then blocks GDM login. Instead `crd-start/setup.sh` installs a user-level unit
(`~/.config/systemd/user/chrome-remote-desktop-console.service`) that is
`WantedBy=graphical-session.target`, so it runs right after the user logs into
the console GNOME session and attaches CRD to the real display. `--child-process`
makes the host run directly in the user session instead of relaunching itself
via root systemd, and the explicit `--config` pins the host's canonical config
(`host#<md5-of-hostname>.json`, computed by `setup.sh`).

Related commands:

```bash
~/Workspace/chrome-remote-desktop-shared-session/crd-start/setup.sh   # (re)install
~/Workspace/chrome-remote-desktop-shared-session/crd-start/disable.sh # stop + disable
```

## Requirements

- Console must be logged into a GNOME session owned by the same user (the
  session runs its X server with `/run/user/<uid>/gdm/Xauthority`).
- The console must stay logged in; the remote view is a mirror of that session.
- The user's account needs sudo.

## Related fix: Nautilus (GNOME Files) activation

DBus-activated apps can fail with "Failed to open display" after the shared-
session setup. See `nautilus-fix/` for the Nautilus fix and its `setup.sh`.

## Caveats

- **Breaks on package update.** The Debian/apt package owns the script, so any
  `chrome-remote-desktop` upgrade overwrites the patch. Re-run `apply.sh` after
  an update.
- The script can change between versions; if `apply.sh` reports the installed
  file differs from `patch/chrome-remote-desktop-original`, regenerate the
  patch against the new version first.
- Audio/other features behave as in the console session.
