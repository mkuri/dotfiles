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


_mirror_repeat_watcher_started = False


def _mirror_start_repeat_watcher(env):
  """Re-enable X key auto-repeat whenever a remote client disconnects.

  The CRD host turns off auto-repeat on its X server while a client is
  connected and normally restores it on disconnect, but sometimes leaves it
  off. On a virtual session that is harmless; here it is the physical
  console, so local key repeat would stay broken until `xset r on`.
  """
  global _mirror_repeat_watcher_started
  if _mirror_repeat_watcher_started:
    return
  _mirror_repeat_watcher_started = True

  def watch():
    proc = subprocess.Popen(
        ["journalctl", "--follow", "--lines=0", "--identifier=chromoting",
         "--output=cat"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    for line in proc.stdout:
      if line.startswith("Client disconnected:"):
        # Let the host finish tearing down its input injector first.
        time.sleep(1)
        subprocess.call(["xset", "r", "on"], env=env,
                        stderr=subprocess.DEVNULL)

  threading.Thread(target=watch, daemon=True).start()


def _mirror_launch_server(self, extra_x_args):
  display = _mirror_find_display()
  if display is None:
    raise Exception("No X11 display owned by this user. "
                    "Log in to GNOME (Xorg) on the physical console first.")
  self.child_env["DISPLAY"] = ":%d" % display
  self.child_env["XAUTHORITY"] = "/run/user/%d/gdm/Xauthority" % os.getuid()
  self._wait_for_x()
  _mirror_start_repeat_watcher(dict(self.child_env))
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
