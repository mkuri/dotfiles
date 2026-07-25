#!/usr/bin/env python3
"""Require a normal Codex approval before high-impact shell commands."""

from __future__ import annotations

import json
import os
import re
import shlex
import sys
from collections.abc import Iterable
from typing import Any

SHELL_OPERATORS = {";", "&&", "||", "|", "&", "(", ")"}
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

BREW_MUTATIONS = {
    "install",
    "uninstall",
    "remove",
    "upgrade",
    "update",
    "tap",
    "untap",
    "link",
    "unlink",
    "pin",
    "unpin",
    "autoremove",
    "cleanup",
}

GH_MUTATIONS = {
    "alias": {"delete", "import", "set"},
    "auth": {"login", "logout", "refresh", "setup-git"},
    "config": {"clear-cache", "set"},
    "extension": {"create", "install", "remove", "upgrade"},
    "gpg-key": {"add", "delete"},
    "issue": {
        "close",
        "comment",
        "create",
        "delete",
        "develop",
        "edit",
        "lock",
        "pin",
        "reopen",
        "transfer",
        "unlock",
        "unpin",
    },
    "label": {"clone", "create", "delete", "edit"},
    "pr": {
        "close",
        "comment",
        "create",
        "edit",
        "merge",
        "ready",
        "reopen",
        "review",
        "update-branch",
    },
    "release": {"create", "delete", "edit", "upload"},
    "repo": {"archive", "create", "delete", "edit", "fork", "rename", "sync"},
    "run": {"cancel", "delete", "rerun"},
    "secret": {"delete", "set"},
    "ssh-key": {"add", "delete"},
    "variable": {"delete", "set"},
    "workflow": {"disable", "enable", "run"},
}

CLOUD_MUTATION_WORDS = {
    "add",
    "apply",
    "attach",
    "cancel",
    "close",
    "create",
    "delete",
    "deploy",
    "destroy",
    "detach",
    "disable",
    "enable",
    "execute",
    "import",
    "insert",
    "invoke",
    "login",
    "logout",
    "merge",
    "migrate",
    "move",
    "patch",
    "promote",
    "publish",
    "reboot",
    "remove",
    "rename",
    "replace",
    "reset",
    "resize",
    "restart",
    "restore",
    "resume",
    "revoke",
    "rollback",
    "rotate",
    "set",
    "start",
    "stop",
    "submit",
    "suspend",
    "transfer",
    "unlock",
    "update",
    "upgrade",
    "upload",
}

KUBECTL_MUTATIONS = {
    "annotate",
    "apply",
    "attach",
    "auth",
    "autoscale",
    "cordon",
    "cp",
    "create",
    "delete",
    "drain",
    "edit",
    "exec",
    "expose",
    "label",
    "patch",
    "replace",
    "rollout",
    "run",
    "scale",
    "set",
    "taint",
    "uncordon",
}

DEPLOY_COMMANDS = {
    "firebase": {"deploy", "functions:delete", "hosting:disable"},
    "fly": {"deploy", "launch", "machine", "scale", "secrets"},
    "flyctl": {"deploy", "launch", "machine", "scale", "secrets"},
    "helm": {"install", "rollback", "test", "uninstall", "upgrade"},
    "pulumi": {"cancel", "destroy", "import", "refresh", "state", "up"},
    "railway": {"deploy", "down", "link", "login", "redeploy", "up", "variables"},
    "terraform": {"apply", "destroy", "force-unlock", "import", "login", "state", "taint", "untaint"},
    "terragrunt": {"apply", "destroy", "force-unlock", "import", "run-all", "state", "taint", "untaint"},
    "vercel": {"alias", "deploy", "env", "link", "login", "promote", "redeploy", "remove", "rollback"},
    "wrangler": {"delete", "deploy", "d1", "kv", "login", "pages", "publish", "r2", "secret", "tail", "versions"},
}

GH_GLOBAL_OPTIONS_WITH_VALUES = {
    "--hostname",
    "--repo",
    "-R",
}


def tokenize(command: str) -> list[str]:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
        lexer.whitespace_split = True
        lexer.commenters = ""
        return list(lexer)
    except ValueError:
        return []


def split_segments(tokens: Iterable[str]) -> list[list[str]]:
    segments: list[list[str]] = []
    current: list[str] = []
    for token in tokens:
        if token in SHELL_OPERATORS:
            if current:
                segments.append(current)
                current = []
            continue
        current.append(token)
    if current:
        segments.append(current)
    return segments


def strip_command_wrappers(tokens: list[str]) -> tuple[list[str], str | None]:
    index = 0
    while index < len(tokens) and ASSIGNMENT_RE.match(tokens[index]):
        index += 1

    remaining = tokens[index:]
    if not remaining:
        return [], None

    executable = os.path.basename(remaining[0])
    if executable == "sudo":
        return remaining, "Administrative commands can change the host system."

    if executable == "env":
        index = 1
        while index < len(remaining):
            token = remaining[index]
            if ASSIGNMENT_RE.match(token) or token.startswith("-"):
                index += 1
                continue
            break
        return remaining[index:], None

    if executable in {"command", "nohup"}:
        return remaining[1:], None

    return remaining, None


def first_positional(arguments: list[str], options_with_values: set[str] | None = None) -> str | None:
    options_with_values = options_with_values or set()
    skip_next = False
    for argument in arguments:
        if skip_next:
            skip_next = False
            continue
        if argument == "--":
            continue
        if argument in options_with_values:
            skip_next = True
            continue
        if any(argument.startswith(f"{option}=") for option in options_with_values if option.startswith("--")):
            continue
        if argument.startswith("-"):
            continue
        return argument
    return None


def normalized_words(arguments: Iterable[str]) -> set[str]:
    words: set[str] = set()
    for argument in arguments:
        if argument.startswith("-"):
            continue
        words.add(argument.lower())
        words.update(part for part in re.split(r"[-_:]", argument.lower()) if part)
    return words


def has_cloud_mutation(arguments: list[str]) -> bool:
    words = normalized_words(arguments)
    return bool(words & CLOUD_MUTATION_WORDS)


def classify_git(arguments: list[str]) -> str | None:
    subcommand = first_positional(arguments, {"-C", "-c", "--git-dir", "--work-tree"})
    if subcommand == "push":
        if {"--dry-run", "-n"} & set(arguments):
            return None
        return "Pushing changes modifies a remote repository."
    if subcommand == "clean":
        return "Cleaning a worktree can permanently delete untracked files."
    if subcommand == "reset" and {"--hard", "--merge", "--keep"} & set(arguments):
        return "This reset mode can discard local work."
    if subcommand == "restore":
        return "Restoring paths can overwrite local changes."
    if subcommand == "checkout" and ({"--", "--force", "-f"} & set(arguments)):
        return "This checkout can overwrite local changes."
    if subcommand == "switch" and ({"--discard-changes", "--force", "-f"} & set(arguments)):
        return "This branch switch can overwrite local changes."
    if subcommand == "branch" and {"-d", "-D", "--delete"} & set(arguments):
        return "Deleting a local branch can discard an otherwise unreferenced commit."
    if subcommand == "tag" and {"-d", "--delete"} & set(arguments):
        return "Deleting a tag changes repository metadata."
    return None


def classify_gh(arguments: list[str]) -> str | None:
    group = first_positional(arguments, GH_GLOBAL_OPTIONS_WITH_VALUES)
    if group is None:
        return None

    group_index = arguments.index(group)
    group_arguments = arguments[group_index + 1 :]

    if group == "api":
        lowered = [argument.lower() for argument in group_arguments]
        sends_data = any(
            argument in {"-f", "-F", "--field", "--raw-field", "--input"}
            or argument.startswith(("--field=", "--raw-field=", "--input="))
            for argument in group_arguments
        )
        explicit_write = any(
            argument in {"-X", "--method"}
            and index + 1 < len(lowered)
            and lowered[index + 1] not in {"get", "head", "options"}
            for index, argument in enumerate(group_arguments)
        ) or any(
            argument.startswith(("-XPOST", "-XPUT", "-XPATCH", "-XDELETE"))
            or argument.startswith("--method=")
            and argument.split("=", 1)[1].lower() not in {"get", "head", "options"}
            for argument in group_arguments
        )
        graphql_mutation = any("mutation" in argument.lower() for argument in group_arguments)
        if sends_data or explicit_write or graphql_mutation:
            return "This GitHub API request may change external state."
        return None

    action = first_positional(group_arguments, GH_GLOBAL_OPTIONS_WITH_VALUES)
    if action in GH_MUTATIONS.get(group, set()):
        return f"The GitHub command 'gh {group} {action}' changes external or authentication state."
    return None


def classify_curl(arguments: list[str]) -> str | None:
    data_prefixes = (
        "--data=",
        "--data-ascii=",
        "--data-binary=",
        "--data-raw=",
        "--data-urlencode=",
        "--form=",
        "--form-string=",
        "--upload-file=",
    )
    data_options = {
        "-d",
        "-F",
        "-T",
        "--data",
        "--data-ascii",
        "--data-binary",
        "--data-raw",
        "--data-urlencode",
        "--form",
        "--form-string",
        "--upload-file",
    }
    if any(argument in data_options or argument.startswith(data_prefixes) for argument in arguments):
        return "Sending request data or uploading a file can change an external service."

    for index, argument in enumerate(arguments):
        lowered = argument.lower()
        if argument in {"-X", "--request"} and index + 1 < len(arguments):
            method = arguments[index + 1].lower()
            if method not in {"get", "head", "options"}:
                return f"The HTTP method {method.upper()} can change an external service."
        if lowered.startswith("-x") and len(lowered) > 2:
            method = lowered[2:]
            if method not in {"get", "head", "options"}:
                return f"The HTTP method {method.upper()} can change an external service."
        if lowered.startswith("--request="):
            method = lowered.split("=", 1)[1]
            if method not in {"get", "head", "options"}:
                return f"The HTTP method {method.upper()} can change an external service."
    return None


def classify_wget(arguments: list[str]) -> str | None:
    if any(
        argument in {"--post-data", "--post-file"}
        or argument.startswith(("--post-data=", "--post-file="))
        for argument in arguments
    ):
        return "Posting request data can change an external service."
    for index, argument in enumerate(arguments):
        if argument == "--method" and index + 1 < len(arguments):
            if arguments[index + 1].lower() not in {"get", "head", "options"}:
                return "This HTTP method can change an external service."
        if argument.startswith("--method="):
            if argument.split("=", 1)[1].lower() not in {"get", "head", "options"}:
                return "This HTTP method can change an external service."
    return None


def classify_segment(tokens: list[str]) -> str | None:
    remaining, wrapper_risk = strip_command_wrappers(tokens)
    if wrapper_risk:
        return wrapper_risk
    if not remaining:
        return None

    executable = os.path.basename(remaining[0]).lower()
    arguments = remaining[1:]

    if executable in {"bash", "sh", "zsh"}:
        for option in ("-c", "-lc"):
            if option in arguments:
                index = arguments.index(option)
                if index + 1 < len(arguments):
                    return classify_command(arguments[index + 1])
        return None

    if executable in {"rm", "rmdir", "unlink", "shred", "truncate"}:
        return f"The command '{executable}' deletes or irreversibly changes local data."

    if executable == "find" and "-delete" in arguments:
        return "The find command deletes matching local files."

    if executable == "dd" and any(argument.startswith("of=") for argument in arguments):
        return "Writing with dd can overwrite local devices or files."

    if executable == "git":
        return classify_git(arguments)

    if executable == "gh":
        return classify_gh(arguments)

    if executable == "curl":
        return classify_curl(arguments)

    if executable == "wget":
        return classify_wget(arguments)

    if executable == "brew":
        action = first_positional(arguments)
        if action in BREW_MUTATIONS:
            return f"The Homebrew command 'brew {action}' changes host-managed software."
        if action == "services":
            service_action = first_positional(arguments[arguments.index(action) + 1 :])
            if service_action not in {None, "list", "info"}:
                return "Changing a Homebrew service requires explicit approval."
        return None

    if executable == "gcloud":
        if "emulators" in arguments:
            return None
        runs_remote_workflow = "workflows" in arguments and "run" in arguments
        if runs_remote_workflow or has_cloud_mutation(arguments) or any(
            argument in {"add-iam-policy-binding", "remove-iam-policy-binding", "set-iam-policy", "ssh", "scp"}
            for argument in arguments
        ):
            return "This Google Cloud command may change cloud resources, credentials, or remote systems."
        return None

    if executable == "doctl":
        if has_cloud_mutation(arguments) or "ssh" in arguments:
            return "This DigitalOcean command may change cloud resources, credentials, or remote systems."
        return None

    if executable == "kubectl":
        action = first_positional(arguments)
        if action in KUBECTL_MUTATIONS:
            return f"The Kubernetes command 'kubectl {action}' may change a cluster or remote workload."
        return None

    if executable in DEPLOY_COMMANDS:
        if executable == "wrangler" and "--local" in arguments:
            return None
        action = first_positional(arguments)
        if action in DEPLOY_COMMANDS[executable]:
            return f"The command '{executable} {action}' may change deployed or cloud resources."
        return None

    if executable == "docker":
        action = first_positional(arguments)
        if action in {"login", "logout", "push"}:
            return f"The Docker command 'docker {action}' changes credentials or a remote registry."
        if action in {"system", "volume", "network", "image", "container"}:
            words = normalized_words(arguments)
            if words & {"delete", "prune", "remove", "rm"}:
                return "This Docker command may delete local development data."
        if action == "compose" and ({"rm", "--volumes", "-v"} & set(arguments)):
            return "This Docker Compose command may delete local development data."
        return None

    return None


def classify_command(command: str) -> str | None:
    tokens = tokenize(command)
    for segment in split_segments(tokens):
        risk = classify_segment(segment)
        if risk:
            return risk
    return None


def requests_escalation(tool_input: dict[str, Any]) -> bool:
    permission = tool_input.get("sandbox_permissions", tool_input.get("sandboxPermissions"))
    return permission == "require_escalated"


def denial(reason: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"Approval required: {reason} Retry the exact command with "
                'sandbox_permissions="require_escalated" and a user-facing justification. '
                "Do not use another command or tool to bypass this policy."
            ),
        }
    }


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return 0

    if payload.get("tool_name") != "Bash":
        return 0

    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return 0

    command = tool_input.get("command", tool_input.get("cmd"))
    if not isinstance(command, str) or not command:
        return 0

    reason = classify_command(command)
    if reason and not requests_escalation(tool_input):
        json.dump(denial(reason), sys.stdout)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
