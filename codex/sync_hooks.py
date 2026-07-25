#!/usr/bin/env python3
"""Merge dotfiles-owned Codex hooks into the local hooks.json."""

from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Synchronize dotfiles-owned hooks into Codex hooks.json."
    )
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument(
        "--check",
        action="store_true",
        help="Exit with status 1 when the local hooks are out of sync.",
    )
    action.add_argument(
        "--apply",
        action="store_true",
        help="Apply managed hooks while preserving all other local hooks.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path.home() / ".codex" / "hooks.json",
        help="Codex hooks file to inspect or update.",
    )
    parser.add_argument(
        "--managed",
        type=Path,
        default=Path(__file__).with_name("managed-hooks.json"),
        help="JSON fragment containing the dotfiles-owned hooks.",
    )
    return parser.parse_args()


def load_json(path: Path, *, missing_ok: bool = False) -> dict[str, Any]:
    if missing_ok and not path.exists():
        return {}
    try:
        with path.open(encoding="utf-8") as file:
            value = json.load(file)
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read valid JSON from {path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return value


def validate_managed(data: dict[str, Any]) -> None:
    hooks = data.get("hooks")
    if set(data) != {"hooks"} or not isinstance(hooks, dict) or not hooks:
        raise ValueError("managed hooks must contain only a non-empty hooks object")
    for event, entries in hooks.items():
        if not isinstance(event, str) or not isinstance(entries, list):
            raise ValueError("managed hook events must map to arrays")
        for entry in entries:
            if not isinstance(entry, dict) or not isinstance(entry.get("hooks"), list):
                raise ValueError("managed hook entries must contain a hooks array")
            for hook in entry["hooks"]:
                if not isinstance(hook, dict) or not isinstance(hook.get("command"), str):
                    raise ValueError("managed hooks must contain command objects")


def merge_entry(existing: dict[str, Any], managed: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(existing)
    for key, value in managed.items():
        if key != "hooks":
            merged[key] = copy.deepcopy(value)

    existing_hooks = merged.setdefault("hooks", [])
    if not isinstance(existing_hooks, list):
        existing_hooks = []
        merged["hooks"] = existing_hooks
    managed_hooks = managed["hooks"]
    for managed_hook in managed_hooks:
        command = managed_hook.get("command")
        matching_index = next(
            (
                index
                for index, hook in enumerate(existing_hooks)
                if isinstance(hook, dict) and hook.get("command") == command
            ),
            None,
        )
        if matching_index is None:
            existing_hooks.append(copy.deepcopy(managed_hook))
        else:
            existing_hooks[matching_index] = copy.deepcopy(managed_hook)
    return merged


def merge_hooks(target: dict[str, Any], managed: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(target)
    hooks = merged.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("target hooks must be an object")

    for event, managed_entries in managed["hooks"].items():
        existing_entries = hooks.setdefault(event, [])
        if not isinstance(existing_entries, list):
            raise ValueError(f"target hook event must be an array: {event}")
        for managed_entry in managed_entries:
            matcher = managed_entry.get("matcher")
            matching_index = next(
                (
                    index
                    for index, entry in enumerate(existing_entries)
                    if isinstance(entry, dict) and entry.get("matcher") == matcher
                ),
                None,
            )
            if matching_index is None:
                existing_entries.append(copy.deepcopy(managed_entry))
            else:
                existing_entries[matching_index] = merge_entry(
                    existing_entries[matching_index], managed_entry
                )
    return merged


def write_atomic(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = 0o600
    try:
        mode = stat.S_IMODE(path.stat().st_mode)
    except FileNotFoundError:
        pass

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            os.chmod(temporary_path, mode)
            json.dump(data, temporary, indent=2)
            temporary.write("\n")
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def synchronize(
    target: Path, managed: Path, *, apply: bool
) -> tuple[bool, str]:
    managed_data = load_json(managed)
    validate_managed(managed_data)
    target_exists = target.exists() or target.is_symlink()
    target_data = load_json(target, missing_ok=True) if target_exists else {}
    target_is_symlink = target.is_symlink()
    merged = merge_hooks(target_data, managed_data)

    if not target_is_symlink and merged == target_data:
        return False, f"unchanged: {target}"
    if not apply:
        reason = "legacy symlink" if target_is_symlink else "managed hooks differ"
        return True, f"out of sync: {target} ({reason})"

    write_atomic(target, merged)
    action = "migrated symlink and updated" if target_is_symlink else "updated"
    return True, f"{action}: {target}"


def main() -> int:
    arguments = parse_args()
    try:
        changed, message = synchronize(
            arguments.target.expanduser(),
            arguments.managed.expanduser(),
            apply=arguments.apply,
        )
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2

    print(message)
    if arguments.check and changed:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
