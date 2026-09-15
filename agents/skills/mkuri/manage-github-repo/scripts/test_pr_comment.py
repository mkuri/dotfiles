"""Behavioral checks for PR action validation and interrupted execution."""

import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).with_name("github-pr-comment")
loader = importlib.machinery.SourceFileLoader("pr_comment", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
helper = importlib.util.module_from_spec(spec)
loader.exec_module(helper)


def batch():
    return {"request_id": "test-batch-0001", "repo": "owner/repo", "pr": 7, "actions": [
        {"type": "react", "surface": "review", "comment_id": 10, "content": "eyes"},
        {"type": "reply", "comment_id": 10, "body": "Fixed in abc123.\n\nVerified."},
        {"type": "resolve", "thread_id": "PRRT_123"}]}


class FakeGitHub:
    def __init__(self):
        self.comments = []
        self.reactions = []
        self.resolved = False
        self.writes = []
        self.actor = 99
        self.comment_pr = 7
        self.thread_pr = 7
        self.reply_parent = None
        self.lose_reply_response = False
        self.fail_reply = False
        self.fail_list = False

    def thread(self, thread_id):
        return {"id": thread_id, "isResolved": self.resolved, "pullRequest": {
            "number": self.thread_pr, "repository": {"nameWithOwner": "owner/repo"}}}

    def api(self, endpoint, payload=None, paginate=False):
        if endpoint == "user":
            return {"id": self.actor}
        if endpoint == "repos/owner/repo/pulls/7":
            return {"number": 7}
        if endpoint in ("repos/owner/repo/pulls/comments/10", "repos/owner/repo/issues/comments/10"):
            return {"pull_request_url": f"https://api.github.com/repos/owner/repo/pulls/{self.comment_pr}",
                    "issue_url": f"https://api.github.com/repos/owner/repo/issues/{self.comment_pr}",
                    "in_reply_to_id": self.reply_parent}
        if payload is None:
            if endpoint.endswith("/reactions"):
                return self.reactions
            if endpoint.endswith("/comments"):
                if self.fail_list:
                    raise RuntimeError("List failed")
                return self.comments
        self.writes.append((endpoint, payload))
        if endpoint.endswith("/reactions"):
            value = {"id": 42, "user": {"id": self.actor}, **payload}
            self.reactions.append(value)
            return value
        if endpoint == "graphql":
            self.resolved = True
            return {"data": {"resolveReviewThread": {"thread": {"id": "PRRT_123", "isResolved": True}}}}
        if self.fail_reply:
            raise RuntimeError("Delivery failed")
        value = {"id": 55, "user": {"id": self.actor}, "created_at": "2026-09-15T00:00:00Z", **payload}
        if endpoint.endswith("/replies"):
            value["in_reply_to_id"] = 10
        self.comments.append(value)
        if self.lose_reply_response:
            raise RuntimeError("Response lost")
        return value


class BatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name) / "state"
        self.github = FakeGitHub()

    def run_batch(self, request=None):
        return helper.run(request or batch(), self.github, self.state)

    def test_order_and_completed_retry(self):
        result = self.run_batch()
        self.assertEqual(result["status"], "complete")
        self.assertEqual(len(self.github.writes), 3)
        self.assertTrue(self.github.writes[0][0].endswith("/reactions"))
        self.assertTrue(self.github.writes[1][0].endswith("/replies"))
        self.assertEqual(self.github.writes[2][1]["query"], helper.RESOLVE)
        self.run_batch()
        self.assertEqual(len(self.github.writes), 3)

    def test_reply_lost_response_reconciles_and_resumes(self):
        self.github.lose_reply_response = True
        result = self.run_batch()
        self.assertEqual(result["status"], "incomplete")
        self.assertEqual(result["pending"], 1)
        self.assertEqual(result["remaining"], [2])
        self.assertFalse(self.github.resolved)
        result = self.run_batch()
        self.assertEqual(result["status"], "complete")
        self.assertEqual(len(self.github.comments), 1)
        self.assertEqual(len(self.github.writes), 3)

    def test_uncertain_missing_reply_never_reposts_or_resolves(self):
        self.github.fail_reply = True
        self.run_batch()
        self.github.fail_reply = False
        result = self.run_batch()
        self.assertEqual(result["status"], "incomplete")
        self.assertIn("Uncertain", result["error"])
        self.assertEqual(len(self.github.writes), 2)
        self.assertFalse(self.github.resolved)

    def test_read_failure_can_resume_without_uncertain_delivery(self):
        self.github.fail_list = True
        self.run_batch()
        self.github.fail_list = False
        self.assertEqual(self.run_batch()["status"], "complete")

    def test_entire_batch_membership_checked_before_writing(self):
        for field in ("comment_pr", "thread_pr"):
            with self.subTest(field=field):
                self.github = FakeGitHub()
                setattr(self.github, field, 8)
                with self.assertRaisesRegex(ValueError, "specified PR"):
                    self.run_batch()
                self.assertEqual(self.github.writes, [])

    def test_reply_to_reply_rejected(self):
        self.github.reply_parent = 9
        with self.assertRaisesRegex(ValueError, "root review comment"):
            self.run_batch()
        self.assertEqual(self.github.writes, [])

    def test_changed_payload_or_account_cannot_resume(self):
        self.run_batch()
        modified = batch()
        modified["actions"][1]["body"] = "Changed"
        with self.assertRaisesRegex(ValueError, "different content"):
            self.run_batch(modified)
        self.github.actor = 100
        with self.assertRaisesRegex(ValueError, "original GitHub account"):
            self.run_batch()

    def test_conversation_comment_and_reaction(self):
        request = batch()
        request["actions"] = [{"type": "comment", "body": "@codex review"},
                              {"type": "react", "surface": "conversation", "comment_id": 10, "content": "+1"}]
        result = self.run_batch(request)
        self.assertEqual(result["completed"][0]["result"]["created_at"], "2026-09-15T00:00:00Z")
        self.assertEqual(self.github.writes[0][0], "repos/owner/repo/issues/7/comments")
        self.assertEqual(self.github.writes[1][0], "repos/owner/repo/issues/comments/10/reactions")

    def test_rejects_unknown_or_dangerous_actions_before_any_api(self):
        cases = [dict(type="delete", comment_id=10), dict(type="resolve", thread_id="x", query="mutation{}"),
                 dict(type="react", surface="review", comment_id=True, content="+1"),
                 dict(type="react", surface="review", comment_id=10, content="arbitrary"),
                 dict(type="comment", body=""), dict(type="comment", body="hello", endpoint="anything")]
        for action in cases:
            request = batch()
            request["actions"].append(action)
            with self.subTest(action=action), self.assertRaises(ValueError):
                self.run_batch(request)
        self.assertEqual(self.github.writes, [])

    def test_simultaneous_batch_rejected(self):
        self.state.mkdir(mode=0o700)
        with (self.state / "lock").open("w") as lock:
            helper.fcntl.flock(lock, helper.fcntl.LOCK_EX)
            with self.assertRaisesRegex(ValueError, "Another PR comment batch"):
                self.run_batch()

    def test_validate_only_has_no_side_effects(self):
        request = Path(self.temp.name) / "request.json"
        request.write_text(json.dumps(batch()))
        result = subprocess.run([str(SOURCE), "--request-file", str(request), "--validate-only"],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"status": "valid"})
        self.assertFalse(self.state.exists())


class TransportTests(unittest.TestCase):
    def test_payload_uses_stdin_not_shell_and_pagination_flattens(self):
        with patch.object(helper.subprocess, "run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, '[[{"id":1}],[{"id":2}]]', '')
            self.assertEqual(helper.GitHub().api("repos/owner/repo/pulls/7/comments", paginate=True),
                             [{"id": 1}, {"id": 2}])
            self.assertIn("--paginate", run.call_args.args[0])
            self.assertIn("--slurp", run.call_args.args[0])
            run.return_value = subprocess.CompletedProcess([], 0, '{"id":3}', '')
            payload = {"body": "$(touch /tmp/should-not-exist) `id`\n\nText"}
            helper.GitHub().api("repos/owner/repo/issues/7/comments", payload)
            command = run.call_args.args[0]
            self.assertEqual(command[:4], ["gh", "api", "--hostname", "github.com"])
            self.assertNotIn(payload["body"], command)
            self.assertEqual(json.loads(run.call_args.kwargs["input"]), payload)
            self.assertFalse(run.call_args.kwargs.get("shell", False))

    def test_graphql_errors_fail_even_with_exit_zero(self):
        with patch.object(helper.subprocess, "run") as run:
            run.return_value = subprocess.CompletedProcess([], 0, '{"errors":[{"message":"denied"}]}', '')
            with self.assertRaisesRegex(ValueError, "GraphQL error"):
                helper.GitHub().api("graphql", {"query": helper.RESOLVE})


class InstallationTests(unittest.TestCase):
    def test_installation_is_repeatable_and_preserves_other_state(self):
        root = SOURCE.resolve().parents[5]
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".codex/rules").mkdir(parents=True)
            existing = home / ".codex/rules/default.rules"
            existing.write_text("# Existing user rules\n")
            (home / ".claude").mkdir()
            settings = home / ".claude/settings.json"
            settings.write_text(json.dumps({"hooks": {"Stop": []}, "permissions": {"defaultMode": "default"}}))
            command = ["sh", str(root / "agents/setup.sh"), "--pr-comments-only"]
            environment = dict(os.environ, AGENT_CONFIG_HOME=directory)
            for _ in range(2):
                result = subprocess.run(command, env=environment, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(existing.read_text(), "# Existing user rules\n")
            installed = home / ".local/bin/github-pr-comment"
            self.assertEqual(installed.resolve(), SOURCE.resolve())
            self.assertTrue(os.access(installed, os.X_OK))
            self.assertTrue((home / ".codex/rules/github-pr-comments.rules").is_symlink())
            value = json.loads(settings.read_text())
            self.assertEqual(value["hooks"], {"Stop": []})
            self.assertEqual(value["permissions"]["defaultMode"], "default")
            self.assertIn("Bash(github-pr-comment *)", value["permissions"]["allow"])
            self.assertIn("Bash(gh api * -f *)", value["permissions"]["ask"])
            self.assertFalse((home / ".codex/config.toml").exists())

    def test_unrelated_executable_is_not_replaced(self):
        root = SOURCE.resolve().parents[5]
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".local/bin").mkdir(parents=True)
            installed = home / ".local/bin/github-pr-comment"
            installed.write_text("existing command")
            result = subprocess.run(["sh", str(root / "agents/setup.sh"), "--pr-comments-only"],
                                    env=dict(os.environ, AGENT_CONFIG_HOME=directory),
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(installed.read_text(), "existing command")
            self.assertFalse((home / ".claude/settings.json").exists())


if __name__ == "__main__":
    unittest.main()
