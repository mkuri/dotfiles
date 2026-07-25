from __future__ import annotations

import json
from pathlib import Path
import tempfile
import time
import unittest

import sync_hooks


MANAGED_HOOKS = Path(__file__).with_name("managed-hooks.json")


class SyncHooksTest(unittest.TestCase):
    def test_preserves_existing_hooks_and_adds_managed_hook(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "hooks.json"
            target.write_text(
                json.dumps(
                    {
                        "description": "personal hooks",
                        "hooks": {
                            "SessionStart": [
                                {"hooks": [{"type": "command", "command": "keep"}]}
                            ]
                        },
                    }
                ),
                encoding="utf-8",
            )

            changed, _ = sync_hooks.synchronize(target, MANAGED_HOOKS, apply=True)

            self.assertTrue(changed)
            data = json.loads(target.read_text(encoding="utf-8"))
            self.assertEqual(data["description"], "personal hooks")
            self.assertEqual(data["hooks"]["SessionStart"][0]["hooks"][0]["command"], "keep")
            self.assertEqual(len(data["hooks"]["PreToolUse"]), 1)

    def test_second_apply_does_not_rewrite_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "hooks.json"
            sync_hooks.synchronize(target, MANAGED_HOOKS, apply=True)
            first_content = target.read_bytes()
            first_mtime = target.stat().st_mtime_ns
            time.sleep(0.01)

            changed, message = sync_hooks.synchronize(target, MANAGED_HOOKS, apply=True)

            self.assertFalse(changed)
            self.assertIn("unchanged:", message)
            self.assertEqual(target.read_bytes(), first_content)
            self.assertEqual(target.stat().st_mtime_ns, first_mtime)

    def test_check_detects_drift_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "hooks.json"
            target.write_text("{}\n", encoding="utf-8")
            original = target.read_bytes()

            changed, message = sync_hooks.synchronize(target, MANAGED_HOOKS, apply=False)

            self.assertTrue(changed)
            self.assertIn("out of sync:", message)
            self.assertEqual(target.read_bytes(), original)

    def test_apply_replaces_symlink_without_changing_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "legacy-hooks.json"
            source.write_text(json.dumps({"hooks": {"Stop": []}}), encoding="utf-8")
            target = root / "hooks.json"
            target.symlink_to(source)
            source_content = source.read_bytes()

            changed, message = sync_hooks.synchronize(target, MANAGED_HOOKS, apply=True)

            self.assertTrue(changed)
            self.assertIn("migrated symlink", message)
            self.assertFalse(target.is_symlink())
            self.assertEqual(source.read_bytes(), source_content)
            self.assertEqual(len(json.loads(target.read_text())["hooks"]["PreToolUse"]), 1)


if __name__ == "__main__":
    unittest.main()
