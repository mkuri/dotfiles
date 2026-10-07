# dotfiles: mirror physical display
# Inserted into /opt/google/chrome-remote-desktop/chrome-remote-desktop by
# apply-mirror-patch.sh. Instead of starting a virtual Xorg/Xvfb + desktop
# session, attach the host to the user's existing GDM X11 session so that
# GPU-accelerated apps (e.g. rviz) render at full speed.


def _mirror_find_display():
  """Return the display number of an X server socket owned by this user."""
  uid = os.getuid()
  for name in sorted(os.listdir("/tmp/.X11-unix")):
    if not (name.startswith("X") and name[1:].isdigit()):
      continue
    if os.stat(os.path.join("/tmp/.X11-unix", name)).st_uid == uid:
      return int(name[1:])
  return None


def _mirror_launch_server(self, extra_x_args):
  display = _mirror_find_display()
  if display is None:
    raise Exception("No X11 display owned by this user. "
                    "Log in to GNOME (Xorg) on the physical console first.")
  self.child_env["DISPLAY"] = ":%d" % display
  self.child_env["XAUTHORITY"] = "/run/user/%d/gdm/Xauthority" % os.getuid()
  self._wait_for_x()
  # CRD only starts the host while server_proc is set, and SIGTERMs it on
  # teardown. Track a placeholder that exits when the real X server goes away,
  # so the physical X server is never signalled by CRD.
  self.server_proc = subprocess.Popen(
      ["sh", "-c", "while xdpyinfo >/dev/null 2>&1; do sleep 5; done"],
      env=self.child_env)


def _mirror_launch_desktop_session(self):
  # The desktop session is the one already running on the physical console.
  pass


XDesktop._launch_server = _mirror_launch_server
XDesktop.launch_desktop_session = _mirror_launch_desktop_session
