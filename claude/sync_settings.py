#!/usr/bin/env python3
"""Merge dotfiles-shared Claude settings into the local user settings."""

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


SHARED_OBJECT_KEYS = ("enabledPlugins", "extraKnownMarketplaces")
SHARED_KEYS = set(SHARED_OBJECT_KEYS)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Synchronize dotfiles-shared settings into Claude settings.json."
    )
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument(
        "--check",
        action="store_true",
        help="Exit with status 1 when the local settings are out of sync.",
    )
    action.add_argument(
        "--apply",
        action="store_true",
        help="Apply shared settings while preserving all other local settings.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path.home() / ".claude" / "settings.json",
        help="Claude user settings to inspect or update.",
    )
    parser.add_argument(
        "--shared",
        type=Path,
        default=Path(__file__).with_name("shared-settings.json"),
        help="JSON fragment containing the dotfiles-shared settings.",
    )
    parser.add_argument(
        "--legacy-source",
        type=Path,
        default=Path(__file__).with_name("settings.json"),
        help="Expected legacy symlink source during migration.",
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


def validate_shared(data: dict[str, Any]) -> None:
    if set(data) != SHARED_KEYS:
        raise ValueError("shared settings contain unexpected or missing keys")
    for key in SHARED_OBJECT_KEYS:
        if not isinstance(data.get(key), dict):
            raise ValueError(f"shared setting {key} must be an object")


def resolve_lexically(path: Path) -> Path:
    return Path(os.path.abspath(os.path.realpath(path)))


def is_expected_legacy_symlink(target: Path, legacy_source: Path) -> bool:
    return target.is_symlink() and resolve_lexically(target) == resolve_lexically(
        legacy_source
    )


def merge_settings(target: dict[str, Any], shared: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(target)
    for key in SHARED_OBJECT_KEYS:
        existing = merged.get(key)
        if existing is None:
            existing = {}
            merged[key] = existing
        if not isinstance(existing, dict):
            raise ValueError(f"target setting {key} must be an object")
        existing.update(copy.deepcopy(shared[key]))
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
    target: Path,
    shared: Path,
    legacy_source: Path,
    *,
    apply: bool,
) -> tuple[bool, str]:
    shared_data = load_json(shared)
    validate_shared(shared_data)

    target_is_symlink = target.is_symlink()
    if target_is_symlink and not is_expected_legacy_symlink(target, legacy_source):
        raise ValueError(f"refusing to replace unrelated symlink: {target}")

    target_data = load_json(target, missing_ok=True)
    merged = merge_settings(target_data, shared_data)
    if not target_is_symlink and merged == target_data:
        return False, f"unchanged: {target}"
    if not apply:
        reason = "legacy symlink" if target_is_symlink else "shared settings differ"
        return True, f"out of sync: {target} ({reason})"

    write_atomic(target, merged)
    action = "migrated symlink and updated" if target_is_symlink else "updated"
    return True, f"{action}: {target}"


def main() -> int:
    arguments = parse_args()
    try:
        changed, message = synchronize(
            arguments.target.expanduser(),
            arguments.shared.expanduser(),
            arguments.legacy_source.expanduser(),
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
