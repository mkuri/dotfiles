from __future__ import annotations

import os
from pathlib import Path
import tempfile
import time
import tomllib
import unittest

import sync_config


SHARED_CONFIG = Path(__file__).with_name("shared-config.toml")


class SyncConfigTest(unittest.TestCase):
    def test_preserves_unmanaged_and_dynamic_settings(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "config.toml"
            target.write_text(
                """
model = "gpt-test"
approval_policy = "never"

[hooks.state."dynamic-hook"]
trusted_hash = "sha256:test"

[shell_environment_policy]
inherit = "all"

[shell_environment_policy.set]
EXISTING_VALUE = "keep"

[permissions.development]
description = "stale"

[permissions.development.network]
enabled = false

[plugins."example@test"]
enabled = true
""".lstrip(),
                encoding="utf-8",
            )

            changed, _ = sync_config.synchronize(
                target, SHARED_CONFIG, apply=True
            )

            self.assertTrue(changed)
            with target.open("rb") as file:
                result = tomllib.load(file)
            self.assertEqual(result["model"], "gpt-test")
            self.assertEqual(
                result["hooks"]["state"]["dynamic-hook"]["trusted_hash"],
                "sha256:test",
            )
            self.assertEqual(
                result["shell_environment_policy"]["set"]["EXISTING_VALUE"],
                "keep",
            )
            self.assertTrue(result["plugins"]["example@test"]["enabled"])
            self.assertEqual(result["approval_policy"], "on-request")
            self.assertTrue(
                result["permissions"]["development"]["network"]["enabled"]
            )
            filesystem = result["permissions"]["development"]["filesystem"]
            self.assertEqual(filesystem["~/.ssh/config"], "read")
            self.assertEqual(filesystem["~/.config/gh/config.yml"], "read")
            self.assertEqual(
                filesystem[":workspace_roots"][".git"],
                "write",
            )

    def test_second_apply_does_not_rewrite_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "config.toml"
            sync_config.synchronize(target, SHARED_CONFIG, apply=True)
            first_content = target.read_bytes()
            first_mtime = target.stat().st_mtime_ns
            time.sleep(0.01)

            changed, message = sync_config.synchronize(
                target, SHARED_CONFIG, apply=True
            )

            self.assertFalse(changed)
            self.assertIn("unchanged:", message)
            self.assertEqual(target.read_bytes(), first_content)
            self.assertEqual(target.stat().st_mtime_ns, first_mtime)

    def test_check_detects_drift_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "config.toml"
            target.write_text('model = "gpt-test"\n', encoding="utf-8")
            original = target.read_bytes()

            changed, message = sync_config.synchronize(
                target, SHARED_CONFIG, apply=False
            )

            self.assertTrue(changed)
            self.assertIn("out of sync:", message)
            self.assertEqual(target.read_bytes(), original)

    def test_replaces_legacy_markers_with_shared_markers(self) -> None:
        legacy = """
# BEGIN dotfiles-managed Codex approval policy
model = "gpt-test"
approval_policy = "never"
# END dotfiles-managed Codex approval policy
""".lstrip()

        merged = sync_config.render_merged_config(
            legacy,
            SHARED_CONFIG.read_text(encoding="utf-8"),
        )

        self.assertNotIn("dotfiles-managed", merged)
        self.assertIn("dotfiles-shared Codex configuration", merged)
        self.assertIn('model = "gpt-test"', merged)

    def test_apply_replaces_symlink_without_changing_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "legacy-config.toml"
            source.write_text('model = "gpt-test"\n', encoding="utf-8")
            target = root / "config.toml"
            target.symlink_to(source)
            source_content = source.read_bytes()

            changed, message = sync_config.synchronize(
                target, SHARED_CONFIG, apply=True
            )

            self.assertTrue(changed)
            self.assertIn("migrated symlink", message)
            self.assertFalse(target.is_symlink())
            self.assertEqual(source.read_bytes(), source_content)
            with target.open("rb") as file:
                result = tomllib.load(file)
            self.assertEqual(result["model"], "gpt-test")
            self.assertEqual(result["approval_policy"], "on-request")

    def test_atomic_update_preserves_mode(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "config.toml"
            target.write_text('model = "gpt-test"\n', encoding="utf-8")
            os.chmod(target, 0o640)

            sync_config.synchronize(target, SHARED_CONFIG, apply=True)

            self.assertEqual(target.stat().st_mode & 0o777, 0o640)


if __name__ == "__main__":
    unittest.main()
