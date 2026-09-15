# PR comment actions

Use the installed `github-pr-comment` command for authorized GitHub PR comment
work. The agent decides the content and actions. Do not ask for redundant
confirmation when the current task or this skill already authorizes the work.
Announce the exact repository and PR before invoking it.

Write a JSON request to a temporary file using a file-writing tool. Invoke the
bare installed command as a separate shell call, without `cd`, redirects,
environment assignments, command substitution, or an interpreter wrapper:

```sh
github-pr-comment --request-file /tmp/pr-actions.json
```

The command uses authenticated `gh` against `github.com`. `~/.local/bin` must be
on `PATH`, resolving to the dotfiles-installed executable. Do not modify the
helper or broaden permissions to force a failed action through.

## Request schema

```json
{
  "request_id": "pr123-fix-abc12345",
  "repo": "owner/repo",
  "pr": 123,
  "actions": [
    {"type": "react", "surface": "review", "comment_id": 456, "content": "+1"},
    {"type": "reply", "comment_id": 456, "body": "Fixed in abc12345."},
    {"type": "resolve", "thread_id": "PRRT_example"}
  ]
}
```

- `request_id`: unique batch ID, 8-80 letters, digits, underscores or hyphens.
  Reuse exactly the same request and ID on retries. Use a new ID for genuinely
  new work, such as requesting a review of a new commit.
- `repo`: explicit `owner/repo`; `pr`: positive integer.
- `actions`: 1-100 actions, executed in order. Unknown fields are rejected.
- `comment`: requires `body`; posts to the PR Conversation tab. Use this for
  `@codex review`, including re-review requests.
- `reply`: requires `comment_id` and `body`; the ID must be a root review
  comment, not a reply. The helper verifies it belongs to this PR.
- `react`: requires `surface` (`review` or `conversation`), `comment_id` and
  `content` (`+1`, `-1`, `laugh`, `confused`, `heart`, `hooray`, `rocket`, `eyes`).
- `resolve`: requires a review thread's GraphQL `thread_id`; obtain this from
  the PR's `reviewThreads` query, matching the root comment. The helper checks
  that the thread belongs to the specified PR.
- Bodies are nonempty strings of up to 60000 characters. Preserve paragraphs
  and English GitHub content. Hidden retry markers are appended automatically.

For a review trigger, use a single `comment` action with `body: "@codex review"`.
The result includes the posted comment's `created_at`; pass it directly to
`poll-codex-review.sh` as `since_iso8601` instead of fetching the last comment.

## Results and retry behavior

Exit 0 means `status: complete` (or `valid` with `--validate-only`). Each
completed result includes its zero-based action index and available GitHub ID,
URL, creation time or resolution state. Exit 1 reports invalid input or an
incomplete batch. An incomplete result lists completed, pending and remaining
action indices. Later actions, including Resolve, do not run after failure.

Rerun the identical request on the same machine to resume. Keep the private
journal under `~/.local/state/github-pr-comment`. Completed actions are skipped;
pending comments are reconciled against all pages of GitHub comments and the
authenticated author. If delivery remains uncertain, inspect GitHub and report
the uncertainty. Do not change IDs, delete journals or blindly repost to bypass
that stop. Reactions and resolution are reconciled against current GitHub state.
Do not run the same batch from multiple machines.

`--validate-only` performs schema validation without network calls or state
writes. It does not check GitHub ownership or permissions.

If `gh` is unavailable, use the existing GitHub MCP fallback and its own
permission controls. This command's allowance does not apply to MCP or browsers.
