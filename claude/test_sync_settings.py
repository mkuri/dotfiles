from __future__ import annotations

import json
import os
from pathlib import Path
import tempfile
import time
import unittest

import sync_settings


SHARED_SETTINGS = Path(__file__).with_name("shared-settings.json")


class SyncSettingsTest(unittest.TestCase):
    def test_preserves_local_settings_and_hooks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            target.write_text(
                json.dumps(
                    {
                        "hooks": {"SessionStart": [{"hooks": [{"command": "keep"}]}]},
                        "tui": "classic",
                        "enabledPlugins": {"local@example": True},
                        "extraKnownMarketplaces": {"local": {"source": "local"}},
                    }
                ),
                encoding="utf-8",
            )

            changed, _ = sync_settings.synchronize(
                target,
                SHARED_SETTINGS,
                Path(directory) / "legacy-settings.json",
                apply=True,
            )

            self.assertTrue(changed)
            result = json.loads(target.read_text(encoding="utf-8"))
            self.assertEqual(result["hooks"]["SessionStart"][0]["hooks"][0]["command"], "keep")
            self.assertEqual(result["tui"], "classic")
            self.assertTrue(result["enabledPlugins"]["local@example"])
            self.assertTrue(result["enabledPlugins"]["swift-lsp@claude-plugins-official"])
            self.assertEqual(result["extraKnownMarketplaces"]["local"]["source"], "local")

    def test_second_apply_does_not_rewrite_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            legacy_source = Path(directory) / "legacy-settings.json"
            sync_settings.synchronize(target, SHARED_SETTINGS, legacy_source, apply=True)
            first_content = target.read_bytes()
            first_mtime = target.stat().st_mtime_ns
            time.sleep(0.01)

            changed, message = sync_settings.synchronize(
                target,
                SHARED_SETTINGS,
                legacy_source,
                apply=True,
            )

            self.assertFalse(changed)
            self.assertIn("unchanged:", message)
            self.assertEqual(target.read_bytes(), first_content)
            self.assertEqual(target.stat().st_mtime_ns, first_mtime)

    def test_check_detects_drift_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            target.write_text('{"tui":"classic"}\n', encoding="utf-8")
            original = target.read_bytes()

            changed, message = sync_settings.synchronize(
                target,
                SHARED_SETTINGS,
                Path(directory) / "legacy-settings.json",
                apply=False,
            )

            self.assertTrue(changed)
            self.assertIn("out of sync:", message)
            self.assertEqual(target.read_bytes(), original)

    def test_apply_replaces_expected_legacy_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            legacy_source = root / "legacy-settings.json"
            legacy_source.write_text(
                json.dumps({"hooks": {"Stop": [{"hooks": [{"command": "keep"}]}]}}),
                encoding="utf-8",
            )
            target = root / "settings.json"
            target.symlink_to(legacy_source)
            source_content = legacy_source.read_bytes()

            changed, message = sync_settings.synchronize(
                target,
                SHARED_SETTINGS,
                legacy_source,
                apply=True,
            )

            self.assertTrue(changed)
            self.assertIn("migrated symlink", message)
            self.assertFalse(target.is_symlink())
            self.assertEqual(legacy_source.read_bytes(), source_content)
            result = json.loads(target.read_text(encoding="utf-8"))
            self.assertEqual(result["hooks"]["Stop"][0]["hooks"][0]["command"], "keep")

    def test_rejects_unrelated_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "other-settings.json"
            source.write_text("{}", encoding="utf-8")
            target = root / "settings.json"
            target.symlink_to(source)

            with self.assertRaisesRegex(ValueError, "unrelated symlink"):
                sync_settings.synchronize(
                    target,
                    SHARED_SETTINGS,
                    root / "legacy-settings.json",
                    apply=True,
                )

    def test_atomic_update_preserves_mode(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            target.write_text("{}", encoding="utf-8")
            os.chmod(target, 0o640)

            sync_settings.synchronize(
                target,
                SHARED_SETTINGS,
                Path(directory) / "legacy-settings.json",
                apply=True,
            )

            self.assertEqual(target.stat().st_mode & 0o777, 0o640)


if __name__ == "__main__":
    unittest.main()
