---
name: manage-github-repo
description: Manage GitHub repository work with gh, GitHub MCP fallback, and local git, including issues, labels, branches, commits, pushes, pull requests, cross-tool reviews, checks, merges, and post-merge cleanup. Use whenever Codex is asked to create, update, inspect, or close a GitHub issue; commit or push repository changes; create, update, inspect, or merge a pull request; request a cross-tool review on a pull request; inspect checks; or clean up a GitHub workflow.
---

# Manage a GitHub repository

Use this workflow for the repository the user identifies. If it is unclear,
ask for the exact `owner/repo` before a GitHub-visible mutation.

## Tool policy

- Prefer `gh` for all GitHub-visible reads and mutations when it is available
  and authenticated, including issues, labels, pull requests, checks, reviews,
  merges, and remote branch cleanup.
- When `gh` is unavailable or unauthenticated, use the GitHub MCP tools
  (`mcp__github__*`) as the fallback. Request only the necessary fields, use
  `minimal_output` when the tool supports it, and paginate rather than fetching
  an unbounded result set.
- Use local `git` for worktree inspection, branches, staging, commits, and
  local branch cleanup.
- Do not probe or use SSH from Codex.
- Do not change `origin` or run `gh auth setup-git`.
- Preserve unrelated user changes and never read ignored or sensitive files.

Before a GitHub-visible mutation, resolve and state the exact repository,
issue, pull request, label, or branch target.

## Body text formatting

Write issue bodies, pull request bodies, and review comments as unwrapped
paragraphs: one line per paragraph, with a blank line between paragraphs.
GitHub's issue/PR/comment renderer turns every single newline into a visible
line break, unlike standard CommonMark, which collapses a soft line break into
a space. Hard-wrapping this content at a fixed column width produces choppy,
obviously wrapped-looking prose once rendered on GitHub.

This does not apply to commit message bodies, which conventionally wrap at
around 72 columns and render as plain text, or to Markdown files committed to
the repository, which GitHub renders through its standard file pipeline where
soft line breaks do collapse.

## Issues and labels

Follow the repository's `AGENTS.md` rules for issue classification, labels,
body structure, priorities, dependencies, and design workflows.

Use `gh issue`, `gh label`, and `gh api` for issue operations when using `gh`.
When using the MCP fallback, use the corresponding GitHub MCP tool. Write
substantial issue bodies to an exact temporary Markdown file and pass it with
`--body-file` when using `gh`; otherwise provide the same body to the MCP tool.
Remove temporary files after the command succeeds.

After creating or updating an issue, inspect it with the selected transport and
report its number, labels, state, and URL.

## Prepare a change

1. Confirm the repository and inspect the current branch.
2. If the branch is `main` or `master`, obtain approval for the exact new
   branch name before creating it.
3. Inspect tracked changes without reading ignored or sensitive files.
4. Stage only explicit paths in scope. Never use `git add -A` or `git add .` in
   a mixed worktree.
5. Run checks appropriate to the changed files.
6. Commit with an English Conventional Commit message.

## Push

When `gh` is available and authenticated, verify `gh auth status`, then push
through gh-authenticated HTTPS without changing the user's Git configuration:

```bash
git -c credential.helper= \
  -c 'credential.helper=!gh auth git-credential' \
  push -u https://github.com/<owner>/<repo>.git <branch>
```

When using the MCP fallback, push the branch using the environment's approved
GitHub transport. Do not change `origin` or configure authentication.

## Create or update a pull request

Use `gh pr` for pull request operations when using `gh`; otherwise use the
corresponding GitHub MCP tool.

1. Create or update the pull request with an English Conventional Commit title.
2. Write a substantial body to a temporary Markdown file and use `--body-file`
   when using `gh`; otherwise provide the same body to the MCP tool.
3. Link the tracking issue with a closing keyword when the pull request
   completes it.
4. Inspect the final metadata with the selected transport.
5. Inspect checks with the selected transport.
6. Treat failing checks as blockers unless the user explicitly waives that
   exact check.

Do not merge without explicit authorization for the target pull request.

## Request a cross-tool review

After opening a substantial pull request, get it reviewed by the agent that did
not write the code, so the review is independent. Apply this only to substantial
work: a feature, a non-trivial fix, or any change touching architecture, data
models, security, or external integrations. Skip it for minor changes such as
small bug fixes, formatting, or documentation edits, matching the repository's
small-change policy. When it is unclear whether a change is substantial, ask the
user first.

The two directions use different mechanisms:

- Claude authored the change → request a Codex review by posting `@codex review`
  as a top-level pull request comment with the selected transport
  (`gh pr comment <number> --repo <owner>/<repo> --body '@codex review'` or the
  corresponding GitHub MCP tool). The Codex GitHub app runs the review in the
  cloud.
- Codex authored the change → the review is performed by Claude Code running
  locally on the user's machine, on the Claude Max subscription. Do not post
  `@claude review`: managed cloud review needs a Team or Enterprise plan, and the
  API-key Actions bot is intentionally not used on this account, so the mention
  would do nothing. Codex cannot start a local Claude Code session, so after
  creating the pull request, report that it is ready for a Claude review and give
  the command to run in a Claude Code session: `/review <pull request number or
  URL>`.

Treat the review as best-effort and non-blocking. Post the Codex mention or the
Claude handoff, report it, and continue rather than waiting. If a Codex review
cannot run — for example an out-of-usage or quota message — skip it and note it.
A missing, skipped, or failed cross-tool review is never on its own a reason to
block a merge.

### Waiting for the Codex review result

Codex's response lands in one of two different places, and checking only one
of them silently misses real findings:

- A formal pull request **review** with per-line **inline comments**, which
  carries a `commit_id`. **`gh pr view --comments` does not surface these** —
  it only shows the top-level Conversation tab, so relying on it (or on the
  review's own top-level body/summary text) can look clean while real inline
  findings sit unread in a separate, paginated endpoint.
- A plain **issue-level comment** ("Codex Review: Didn't find any major
  issues") when Codex has no findings at all. Issue comments carry no
  `commit_id`, so this path can only be matched by timestamp against the
  `@codex review` trigger comment, not by commit.

Hand-writing the polling and JSON handling for this in an ad hoc shell script
each time is a proven source of bugs — a from-scratch attempt missed the
inline-comments endpoint entirely, then mixed in stale comments from earlier
rounds, then required an unsatisfiable commit match on the issue-comment path,
then dropped findings past the first pagination page, then corrupted the
captured JSON by round-tripping it through a variable and `echo` (some
shells, zsh's builtin `echo` by default among them, reinterpret backslash
escapes like the `\n` inside a review body and turn valid escaped JSON into
invalid raw control characters). `scripts/poll-codex-review.sh` in this
skill's directory already handles all of that — use it instead of
reimplementing the logic:

```
scripts/poll-codex-review.sh <owner/repo> <pr_number> <commit_sha> <since_iso8601> [max_wait_seconds] [interval_seconds]
```

`commit_sha` is the commit under review (matched as a `commit_id` prefix);
`since_iso8601` is the `@codex review` trigger comment's `created_at`. It
polls both surfaces, paginating each, and exits `0` with the matched review's
findings as JSON on stdout, `1` with a clean-pass comment as JSON, or `2` (a
`{"result":"timeout",...}` line) if neither appeared within
`max_wait_seconds` (default 480, i.e. 8 minutes, kept under common
single-command timeouts) — re-invoke the script on exit `2` to keep polling
rather than treating it as a final answer.

`gh pr comment` prints only the new comment's URL, not its `created_at`, so
`since_iso8601` is not available from that command's own output. Fetch it
right after posting, before launching the poller. This endpoint defaults to
30 items per page in ascending order, so on a pull request with more history
`.[-1]` on an unpaginated call would silently return a stale comment instead
of the one just posted; `--slurp` cannot be combined with `gh api`'s own
`--jq`, so pipe to a separate `jq` and flatten with `.[][]` as
`poll-codex-review.sh` does:

```
gh api --paginate --slurp "repos/<owner>/<repo>/issues/<number>/comments" | jq -r '[.[][]] | last.created_at'
```

The Codex review arrives asynchronously as a pull request comment from the
Codex GitHub app, so its arrival can be detected without the user pasting
anything. When running as Claude Code, after posting `@codex review` and
capturing its timestamp as above, run the script via the Bash tool with
`run_in_background: true` instead of polling from the main session or
delegating to a subagent — the script is already deterministic, so no LLM
needs to reinterpret it. When it completes, act on
its exit code and JSON: report findings on `0`, report a clean pass on `1`,
or on `2` decide whether to relaunch it (for example, up to 3–4 relaunches to
cover roughly the same 30-minute overall budget) before giving up and
reporting a timeout to the user. When using the GitHub MCP fallback instead
of `gh`, the script is unavailable — replicate its matching logic (commit_id
prefix for reviews, timestamp for issue comments; paginate both) using the
corresponding MCP tools.

If there is follow-up work available, continue with it immediately after
launching the background poll rather than waiting for it. Its completion
arrives later as a notification; fold the review result in then, or when next
reporting to the user.

The Codex→Claude direction has no equivalent to poll for: it hands off to the
user running `/review`, not to an event with observable state.

### Respond to review comments

For each individual review comment addressed with a fix, close its thread
explicitly instead of leaving it to a summary reply:

1. React to the comment to acknowledge it, using `gh api -X POST
   repos/<owner>/<repo>/pulls/comments/<comment id>/reactions -f content=+1`
   or the corresponding GitHub MCP tool.
2. Reply on the same thread referencing the commit that fixes it, using `gh api
   -X POST repos/<owner>/<repo>/pulls/<number>/comments -f body='Fixed in
   <sha>.' -F in_reply_to=<comment id>` or the corresponding GitHub MCP tool.
3. Resolve the conversation once the reply is posted, using `gh api graphql`
   with the `resolveReviewThread` mutation against the thread's node ID
   (fetched via the `reviewThreads` GraphQL query on the pull request), or the
   corresponding GitHub MCP tool.

Do this per comment, not only once at the top level, so each finding's thread
shows its own reaction, reply, and resolution.

### Re-review after fixes

When a cross-tool review's findings are addressed with fixes, request another
cross-tool review of the updated pull request through the same mechanism, so
the independent reviewer re-checks the fix rather than assuming it worked.
Check the re-review the same way as the first pass — run
`scripts/poll-codex-review.sh` with the new commit's SHA — since a clean
second pass can introduce new findings distinct from the ones just fixed, not
only confirm or deny the original ones.
Cap this review → fix → re-review cycle at 3 rounds total. If findings remain
unresolved after the third round, stop re-requesting, report the outstanding
findings to the user, and let them decide how to proceed.

## Squash merge

Immediately before an authorized merge, use the selected GitHub transport to:

1. Verify that the pull request is open and mergeable with the selected transport.
2. Re-run checks with the selected transport.
3. Stop on any failing check.
4. Record the head branch name.
5. When using `gh`, squash merge and request remote branch deletion:

   ```bash
   gh pr merge <number> --repo <owner>/<repo> --squash --delete-branch
   ```

   When using the MCP fallback, squash merge and request remote branch deletion
   with the corresponding GitHub MCP tool.
6. Verify `state`, `mergedAt`, and `mergeCommit` with the selected transport.

## Post-merge cleanup

After a verified squash merge, always finish the workflow:

1. Switch to `main`.
2. When using `gh`, pull the merged `main` through gh-authenticated HTTPS:

   ```bash
   git -c credential.helper= \
     -c 'credential.helper=!gh auth git-credential' \
     pull --ff-only https://github.com/<owner>/<repo>.git main
   ```

   When using the MCP fallback, pull through the environment's approved GitHub
   transport without changing `origin` or configuring authentication.

3. Confirm the remote head branch was deleted. If it remains, delete that exact
   branch with `gh api` or the corresponding GitHub MCP tool; never use a broad
   ref or pattern.
4. Delete the exact local head branch after confirming the pull request is
   merged. A squash merge may require `git branch -D`.
5. Remove only temporary files created by this workflow.
6. Confirm that `main` points at the verified merge commit and report any
   unrelated worktree changes without modifying them.

If unrelated changes block switching or pulling, do not stash, reset, delete,
or overwrite them. Report the blocker and leave the merged pull request and
branches in their verified state.

## Report

Report the affected issue or pull request URLs, repository, branch, source
commit, checks, merge commit when present, cleanup result, and any local or
remote branch that remains.
