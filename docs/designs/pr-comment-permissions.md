# PR comment permissions

Status: Approved

## Context and goals

Claude Code and Codex need to post PR comments and complete review conversations
without repeated execution approvals. Agents choose the text, reaction and
whether a thread should be resolved. A shared command executes those decisions.

## Decision

Install `github-pr-comment` in `~/.local/bin`, with that directory on `PATH`.
Allow this command in Claude settings and a separate Codex rule file. Keep the
existing approval policies for other commands. The executable and its install
location are trusted configuration: modifying them changes what the permission
grants. Do not shadow this command elsewhere on `PATH`.

The command accepts a strict JSON batch for one `github.com` repository and PR.
It supports conversation comments, replies to root review comments, reactions
on conversation or review comments, and resolving review threads. It validates
the entire batch and checks all target memberships before its first mutation.
It uses fixed REST endpoints and a fixed GraphQL query/mutation through `gh api`
with argument arrays and JSON on stdin. It does not accept arbitrary API paths,
hosts, queries, shell commands, deletion, editing, review approval or merging.

Execution is sequential and stops at the first failure. Private local journals
under `~/.local/state/github-pr-comment` bind a request ID to its full payload
and authenticated user. A process lock prevents concurrent local batches.
Journals record pending operations before sending and completed operations after
success. Comment bodies carry a hidden marker for reconciliation after a lost
response. Resume the original unchanged request; completed operations are skipped.
If a pending comment cannot be found, stop for inspection instead of risking a
duplicate. Reactions and resolution can be reconciled against current state.

## Alternatives

- Allowing all `gh api` calls grants unrelated API mutations.
- Adding endpoint-specific Claude allow rules conflicts with existing broad ask
  rules. Codex prefix rules cannot express arbitrary PR IDs inside an endpoint.
- Permission hooks would add separate policy implementations for each tool.

## Consequences and limits

This is not an atomic GitHub transaction. State files must be retained for
retries; changing the request ID or deleting state loses that local protection.
Use one machine for a batch: the lock does not coordinate other machines.
No exactly-once guarantee is claimed across machines or external edits/deletions.
GitHub authentication, API authorization and managed execution policies still
apply. Connector and browser permissions are separate.

## References

- [Usage and request schema](../../agents/skills/mkuri/manage-github-repo/references/pr-comment-actions.md)
- [Claude permissions](https://code.claude.com/docs/en/permissions)
- [Codex rules](https://developers.openai.com/codex/rules/)
- [GitHub CLI API transport](https://cli.github.com/manual/gh_api)
- [Review comments](https://docs.github.com/en/rest/pulls/comments)
- [Reactions](https://docs.github.com/en/rest/reactions/reactions)
- [Review thread schema and mutations](https://docs.github.com/en/graphql/reference/pulls)

## Decision log

- 2026-09-15: Approved a shared, narrowly scoped command and per-tool execution
  allowances following user agreement. Keep decisions in the agent and execution
  validation and retry handling in the command.
