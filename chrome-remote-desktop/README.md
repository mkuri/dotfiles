# Chrome Remote Desktop: mirror the physical display

By default, Chrome Remote Desktop (CRD) on Linux starts a separate virtual
X session (Xorg + dummy driver, or Xvfb) for remote connections. That
session has no GPU, so OpenGL apps such as rviz fall back to software
rendering (llvmpipe) and become sluggish.

[`apply-mirror-patch.sh`](apply-mirror-patch.sh) inserts
[`mirror-patch.py`](mirror-patch.py) into CRD's launcher
(`/opt/google/chrome-remote-desktop/chrome-remote-desktop`) so the host
attaches to the existing GDM X11 session on the physical console instead.
Remote clients then see and control the actual monitor, rendered by the
real GPU.

Verified with Ubuntu 24.04 / GNOME on Xorg / `chrome-remote-desktop`
155.0.8059.19.

## What the patch changes

- `XDesktop._launch_server`: instead of starting an X server, pick the
  X socket in `/tmp/.X11-unix` owned by this user, and use GDM's
  `XAUTHORITY` (`/run/user/<uid>/gdm/Xauthority`).
- `XDesktop.launch_desktop_session`: no-op (the GNOME session already
  runs on the console).
- CRD SIGTERMs `server_proc` on teardown, so it is set to a placeholder
  process that exits when the real X server goes away — the physical X
  server is never signalled by CRD.
- Side effect: CRD's `setxkbmap -rules evdev` call is skipped, so the
  console keymap (and xremap) is left alone.

## Requirements / caveats

- The user must be logged in to GNOME **on Xorg** on the physical
  console. Locking the screen is fine; logging out is not.
- Everything done remotely is visible on the physical monitor.
- Keep the client's "Resize desktop to fit" option **off**; otherwise the
  host may change the physical monitor's resolution.

## Setup

1. Install CRD (the `.deb` also registers Google's apt repo):

   ```sh
   curl -fLO https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
   sudo apt install ./chrome-remote-desktop_current_amd64.deb
   ```

2. Apply the patch (the original launcher is kept as `*.orig`):

   ```sh
   ./apply-mirror-patch.sh
   ```

3. Register the host via <https://remotedesktop.google.com/headless>
   (Begin → Next → Authorize), and run the "Debian Linux" command it
   shows on this machine, then set a PIN. The non-headless flow on
   `remotedesktop.google.com/access` requires the CRD Chrome extension,
   which this setup avoids.

## After a CRD upgrade

Package upgrades overwrite the launcher and revert to virtual sessions
(symptom: connecting shows a separate, empty desktop). Re-apply and
restart the service:

```sh
./apply-mirror-patch.sh
sudo systemctl restart chrome-remote-desktop@$USER
```

If the script reports that the insertion point was not found, the
launcher layout changed upstream; re-check `XDesktop._launch_server` and
`launch_desktop_session` against `mirror-patch.py`.
