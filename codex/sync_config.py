#!/usr/bin/env python3
"""Merge dotfiles-shared Codex settings into the local user configuration."""

from __future__ import annotations

import argparse
import copy
import os
from pathlib import Path
import stat
import sys
import tempfile
import tomllib
from dataclasses import dataclass


TOP_LEVEL_KEYS = (
    "approval_policy",
    "approvals_reviewer",
    "default_permissions",
    "web_search",
)
SHELL_ENVIRONMENT_KEYS = (
    "inherit",
    "ignore_default_excludes",
)
PERMISSIONS_PREFIX = ("permissions", "development")
BEGIN_MARKER = "# BEGIN dotfiles-shared Codex configuration"
END_MARKER = "# END dotfiles-shared Codex configuration"
LEGACY_BEGIN_MARKER = "# BEGIN dotfiles-managed Codex approval policy"
LEGACY_END_MARKER = "# END dotfiles-managed Codex approval policy"
MARKER_KEY = "__codex_dotfiles_sync_marker__"


@dataclass
class Section:
    path: tuple[str, ...]
    header: str | None
    body: list[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Synchronize dotfiles-shared settings into Codex config.toml."
    )
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument(
        "--check",
        action="store_true",
        help="Exit with status 1 when the local configuration is out of sync.",
    )
    action.add_argument(
        "--apply",
        action="store_true",
        help="Apply shared settings while preserving all other local settings.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path.home() / ".codex" / "config.toml",
        help="Codex user configuration to inspect or update.",
    )
    parser.add_argument(
        "--shared",
        type=Path,
        default=Path(__file__).with_name("shared-config.toml"),
        help="TOML fragment containing the dotfiles-shared settings.",
    )
    return parser.parse_args()


def load_toml(path: Path, *, missing_ok: bool = False) -> dict[str, object]:
    if missing_ok and not path.exists():
        return {}
    try:
        with path.open("rb") as file:
            return tomllib.load(file)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ValueError(f"cannot read valid TOML from {path}: {error}") from error


def get_path(data: dict[str, object], path: tuple[str, ...]) -> object:
    current: object = data
    for part in path:
        if not isinstance(current, dict) or part not in current:
            raise KeyError(path)
        current = current[part]
    return current


def validate_shared_config(data: dict[str, object]) -> None:
    expected_top_level = set(TOP_LEVEL_KEYS) | {
        "shell_environment_policy",
        "permissions",
    }
    if set(data) != expected_top_level:
        raise ValueError(
            "shared config must contain only the documented dotfiles-owned keys"
        )

    shell_environment = data.get("shell_environment_policy")
    if not isinstance(shell_environment, dict) or set(shell_environment) != set(
        SHELL_ENVIRONMENT_KEYS
    ):
        raise ValueError(
            "shared shell_environment_policy contains unexpected or missing keys"
        )

    permissions = data.get("permissions")
    if not isinstance(permissions, dict) or set(permissions) != {"development"}:
        raise ValueError("shared config must own only permissions.development")


def is_synced(
    target_data: dict[str, object],
    shared_data: dict[str, object],
    *,
    target_is_symlink: bool,
) -> bool:
    if target_is_symlink:
        return False

    try:
        for key in TOP_LEVEL_KEYS:
            if get_path(target_data, (key,)) != get_path(shared_data, (key,)):
                return False
        for key in SHELL_ENVIRONMENT_KEYS:
            path = ("shell_environment_policy", key)
            if get_path(target_data, path) != get_path(shared_data, path):
                return False
        return get_path(target_data, PERMISSIONS_PREFIX) == get_path(
            shared_data, PERMISSIONS_PREFIX
        )
    except KeyError:
        return False


def find_marker_path(value: object, path: tuple[str, ...] = ()) -> tuple[str, ...] | None:
    if isinstance(value, dict):
        if value.get(MARKER_KEY) is True:
            return path
        for key, child in value.items():
            result = find_marker_path(child, path + (str(key),))
            if result is not None:
                return result
    elif isinstance(value, list):
        for child in value:
            result = find_marker_path(child, path)
            if result is not None:
                return result
    return None


def parse_header_path(line: str) -> tuple[str, ...] | None:
    stripped = line.strip()
    if not stripped.startswith("["):
        return None
    if not (
        (stripped.startswith("[[") and "]]" in stripped)
        or (not stripped.startswith("[[") and "]" in stripped)
    ):
        return None

    try:
        parsed = tomllib.loads(f"{line}\n{MARKER_KEY} = true\n")
    except tomllib.TOMLDecodeError:
        return None
    return find_marker_path(parsed)


def split_sections(text: str) -> list[Section]:
    sections = [Section(path=(), header=None, body=[])]
    for line in text.splitlines():
        path = parse_header_path(line)
        if path is None:
            sections[-1].body.append(line)
        else:
            sections.append(Section(path=path, header=line, body=[]))
    return sections


def assignment_path(line: str) -> tuple[str, ...] | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None
    try:
        parsed = tomllib.loads(line)
    except tomllib.TOMLDecodeError:
        return None

    def only_leaf(
        value: object, path: tuple[str, ...] = ()
    ) -> tuple[str, ...] | None:
        if not isinstance(value, dict):
            return path
        if len(value) != 1:
            return None
        key, child = next(iter(value.items()))
        return only_leaf(child, path + (str(key),))

    return only_leaf(parsed)


def should_remove_assignment(
    section_path: tuple[str, ...], relative_path: tuple[str, ...] | None
) -> bool:
    if relative_path is None:
        return False
    full_path = section_path + relative_path
    if len(full_path) == 1 and full_path[0] in TOP_LEVEL_KEYS:
        return True
    if (
        len(full_path) == 2
        and full_path[0] == "shell_environment_policy"
        and full_path[1] in SHELL_ENVIRONMENT_KEYS
    ):
        return True
    return full_path[: len(PERMISSIONS_PREFIX)] == PERMISSIONS_PREFIX


def clean_body(section: Section) -> list[str]:
    return [
        line
        for line in section.body
        if line.strip()
        not in {BEGIN_MARKER, END_MARKER, LEGACY_BEGIN_MARKER, LEGACY_END_MARKER}
        and not should_remove_assignment(section.path, assignment_path(line))
    ]


def trim_blank_lines(lines: list[str]) -> list[str]:
    result = list(lines)
    while result and not result[-1].strip():
        result.pop()
    return result


def nonblank_body(section: Section) -> list[str]:
    return [line for line in section.body if line.strip()]


def render_merged_config(target_text: str, shared_text: str) -> str:
    shared_sections = split_sections(shared_text)
    shared_top = nonblank_body(shared_sections[0])
    shared_shell = next(
        section
        for section in shared_sections
        if section.path == ("shell_environment_policy",)
    )
    shared_permission_sections = [
        section
        for section in shared_sections
        if section.path[: len(PERMISSIONS_PREFIX)] == PERMISSIONS_PREFIX
    ]

    target_sections = split_sections(target_text)
    retained_sections = [
        section
        for section in target_sections
        if section.path[: len(PERMISSIONS_PREFIX)] != PERMISSIONS_PREFIX
    ]

    output: list[str] = []
    top = retained_sections[0]
    output.extend(trim_blank_lines(clean_body(top)))
    if output:
        output.append("")
    output.extend([BEGIN_MARKER, *shared_top, END_MARKER, ""])

    shell_found = False
    for section in retained_sections[1:]:
        body = clean_body(section)
        if section.path == ("shell_environment_policy",):
            shell_found = True
            output.append(section.header or "[shell_environment_policy]")
            output.extend(
                [
                    BEGIN_MARKER,
                    *nonblank_body(shared_shell),
                    END_MARKER,
                ]
            )
            if body and body[0].strip():
                output.append("")
            output.extend(body)
        else:
            output.append(section.header or "")
            output.extend(body)

    if not shell_found:
        output.extend(
            [
                "[shell_environment_policy]",
                BEGIN_MARKER,
                *nonblank_body(shared_shell),
                END_MARKER,
                "",
            ]
        )

    output = trim_blank_lines(output)
    output.extend(["", BEGIN_MARKER])
    for index, section in enumerate(shared_permission_sections):
        if index:
            output.append("")
        output.append(section.header or "")
        output.extend(section.body)
    output.extend([END_MARKER, ""])

    merged = "\n".join(output)
    tomllib.loads(merged)
    return merged


def write_atomic(path: Path, content: str) -> None:
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
            temporary.write(content)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def synchronize(
    target: Path, shared: Path, *, apply: bool
) -> tuple[bool, str]:
    shared_data = load_toml(shared)
    validate_shared_config(shared_data)
    target_exists = target.exists() or target.is_symlink()
    target_data = load_toml(target, missing_ok=True) if target_exists else {}
    target_is_symlink = target.is_symlink()

    if is_synced(
        target_data,
        shared_data,
        target_is_symlink=target_is_symlink,
    ):
        return False, f"unchanged: {target}"

    if not apply:
        reason = "legacy symlink" if target_is_symlink else "shared settings differ"
        return True, f"out of sync: {target} ({reason})"

    target_text = target.read_text(encoding="utf-8") if target_exists else ""
    shared_text = shared.read_text(encoding="utf-8")
    merged = render_merged_config(target_text, shared_text)

    expected = copy.deepcopy(target_data)
    for key in TOP_LEVEL_KEYS:
        expected[key] = copy.deepcopy(shared_data[key])
    shell_environment = expected.setdefault("shell_environment_policy", {})
    if not isinstance(shell_environment, dict):
        raise ValueError("target shell_environment_policy is not a table")
    for key in SHELL_ENVIRONMENT_KEYS:
        shell_environment[key] = copy.deepcopy(
            shared_data["shell_environment_policy"][key]  # type: ignore[index]
        )
    permissions = expected.setdefault("permissions", {})
    if not isinstance(permissions, dict):
        raise ValueError("target permissions is not a table")
    permissions["development"] = copy.deepcopy(
        shared_data["permissions"]["development"]  # type: ignore[index]
    )

    if tomllib.loads(merged) != expected:
        raise ValueError("refusing to write: merged TOML changed unmanaged settings")

    write_atomic(target, merged)
    action = "migrated symlink and updated" if target_is_symlink else "updated"
    return True, f"{action}: {target}"


def main() -> int:
    arguments = parse_args()
    try:
        changed, message = synchronize(
            arguments.target.expanduser(),
            arguments.shared.expanduser(),
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
