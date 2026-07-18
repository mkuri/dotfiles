#!/usr/bin/env python3
"""Record Claude Code session state for status display consumers.

Registered as a Claude Code hook for lifecycle events. Reads one hook
event JSON from stdin and maintains one state file per session at
$XDG_STATE_HOME/claude-sessions/<session_id>.json (default
~/.local/state/claude-sessions/). The schema is a versioned contract
consumed by display tools such as agent-status-bar.

Must never break or slow Claude Code: always exits 0, writes nothing
to stdout.
"""
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

STATE_VERSION = 1

EVENT_STATES = {
    "SessionStart": "idle",
    "UserPromptSubmit": "running",
    "PermissionRequest": "permission",
    "PostToolUse": "running",
    "PostToolUseFailure": "running",
    "Stop": "idle",
    "StopFailure": "idle",
    "Notification": "idle",
}

SHELLS = {"sh", "bash", "zsh", "dash", "fish"}


def default_state_dir():
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return Path(base) / "claude-sessions"


def resolve_claude_pid(start_pid):
    """Walk up past any shell wrapper to the claude process itself.

    Hook commands may run as `sh -c ...`; the shell usually execs a
    single command (making our parent the claude process directly),
    but that is not guaranteed, so skip shell ancestors explicitly.
    """
    pid = start_pid
    for _ in range(5):
        try:
            out = subprocess.run(
                ["ps", "-o", "ppid=,comm=", "-p", str(pid)],
                capture_output=True, text=True, timeout=1, check=True,
            ).stdout.strip().split(None, 1)
        except (subprocess.SubprocessError, OSError, ValueError):
            return pid
        if len(out) < 2 or os.path.basename(out[1].strip()) not in SHELLS:
            return pid
        try:
            pid = int(out[0])
        except ValueError:
            return pid
    return pid


def handle_event(payload, state_dir, now, pid):
    session_id = payload.get("session_id", "")
    if not session_id or "/" in session_id or session_id.startswith("."):
        return
    path = state_dir / f"{session_id}.json"

    event = payload.get("hook_event_name")
    if event == "SessionEnd":
        try:
            path.unlink()
        except OSError:
            pass
        return

    new_state = EVENT_STATES.get(event)
    if new_state is None:
        return

    prev = {}
    try:
        prev = json.loads(path.read_text())
    except (OSError, ValueError):
        pass

    same_state = prev.get("state") == new_state and "since" in prev
    record = {
        "version": STATE_VERSION,
        "session_id": session_id,
        "state": new_state,
        "since": prev["since"] if same_state else now,
        "cwd": payload.get("cwd") or prev.get("cwd", ""),
        "pid": pid,
        "updated_at": now,
    }
    state_dir.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=state_dir, prefix=".tmp-")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(record, f)
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def main():
    try:
        payload = json.load(sys.stdin)
        handle_event(payload, default_state_dir(), time.time(),
                     resolve_claude_pid(os.getppid()))
    except Exception:
        pass


if __name__ == "__main__":
    main()
