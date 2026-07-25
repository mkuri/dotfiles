#!/usr/bin/env python3
"""Tests for the Codex shell approval hook."""

from __future__ import annotations

import unittest

from pre_tool_use import classify_command, denial, requests_escalation


class CommandClassificationTest(unittest.TestCase):
    def test_allows_read_only_and_local_development_commands(self) -> None:
        commands = [
            "git status --short",
            "git diff --stat",
            "git push --dry-run origin main",
            "git switch feature/example",
            "git checkout feature/example",
            "gh pr view 123",
            "gh pr list",
            "curl https://example.com/data.json",
            "curl -X GET https://example.com/data.json",
            "gcloud projects list",
            "gcloud run services describe example",
            "gcloud beta emulators datastore start",
            "doctl compute droplet list",
            "doctl compute ssh-key list",
            "brew info ripgrep",
            "brew list",
            "docker compose up --build",
            "npm ci",
            "wrangler d1 execute database --local",
        ]
        for command in commands:
            with self.subTest(command=command):
                self.assertIsNone(classify_command(command))

    def test_requires_approval_for_destructive_local_commands(self) -> None:
        commands = [
            "rm -rf build",
            "git clean -fdx",
            "git reset --hard HEAD~1",
            "git restore .",
            "git checkout -- src/example.py",
            "git switch --discard-changes feature/example",
            "find . -name '*.tmp' -delete",
            "dd if=image.iso of=/dev/disk2",
            "docker system prune -af",
            "docker compose down --volumes",
        ]
        for command in commands:
            with self.subTest(command=command):
                self.assertIsNotNone(classify_command(command))

    def test_requires_approval_for_external_writes(self) -> None:
        commands = [
            "git push origin main",
            "gh pr create --fill",
            "gh pr merge 123 --squash",
            "gh api repos/example/project/issues -f title=Bug",
            "curl -d '{\"enabled\":true}' https://api.example.com/settings",
            "curl -X DELETE https://api.example.com/items/1",
            "wget --post-data=value https://api.example.com/items",
            "gcloud run deploy example",
            "gcloud projects add-iam-policy-binding example",
            "doctl compute droplet create example",
            "doctl serverless functions invoke example",
            "kubectl apply -f deployment.yaml",
            "terraform apply",
            "vercel deploy --prod",
            "docker push example/image:latest",
        ]
        for command in commands:
            with self.subTest(command=command):
                self.assertIsNotNone(classify_command(command))

    def test_requires_approval_for_homebrew_changes(self) -> None:
        commands = [
            "brew install ripgrep",
            "brew upgrade",
            "brew uninstall ripgrep",
            "brew services restart postgresql",
        ]
        for command in commands:
            with self.subTest(command=command):
                self.assertIsNotNone(classify_command(command))

    def test_checks_each_command_in_a_compound_shell_command(self) -> None:
        self.assertIsNotNone(classify_command("gh pr view 123 && gh pr create --fill"))
        self.assertIsNotNone(classify_command("echo ready | curl -d status=ready https://example.com"))

    def test_checks_nested_shell_commands(self) -> None:
        self.assertIsNotNone(classify_command("bash -lc 'gh pr create --fill'"))

    def test_recognizes_an_escalated_retry(self) -> None:
        self.assertTrue(requests_escalation({"sandbox_permissions": "require_escalated"}))
        self.assertFalse(requests_escalation({"sandbox_permissions": "use_default"}))

    def test_denial_tells_codex_to_request_approval(self) -> None:
        output = denial("Test operation changes external state.")
        hook_output = output["hookSpecificOutput"]
        self.assertEqual(hook_output["permissionDecision"], "deny")
        self.assertIn("require_escalated", hook_output["permissionDecisionReason"])


if __name__ == "__main__":
    unittest.main()
