#!/usr/bin/env python3
"""Reject paths that must not enter version control."""

from __future__ import annotations

import re
import sys
from pathlib import PurePosixPath


SERVICE_ACCOUNT_JSON = re.compile(
    r"(?:^|/)[^/]*service[-_]?account[^/]*\.json$", re.IGNORECASE
)


def is_forbidden(path: str) -> bool:
    normalized = path.replace("\\", "/")
    name = PurePosixPath(normalized).name

    if name == ".env" or (name.startswith(".env.") and name != ".env.example"):
        return True
    if name.endswith((".jks", ".keystore")):
        return True
    if name == "key.properties" or name.endswith("-plan.md"):
        return True
    return bool(SERVICE_ACCOUNT_JSON.search(normalized))


def main() -> int:
    forbidden = [path for path in sys.argv[1:] if is_forbidden(path)]
    if not forbidden:
        return 0

    print("Refusing to commit forbidden paths:", file=sys.stderr)
    for path in forbidden:
        print(f"  - {path}", file=sys.stderr)
    print(
        "Remove sensitive files and working plans from the commit before retrying.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
