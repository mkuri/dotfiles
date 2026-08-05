#!/usr/bin/env bash
#
# Poll a pull request for the Codex review app's response to a specific
# commit. Codex's response lands in one of two places:
#
#   - a formal PR review (has commit_id) with per-line inline comments, or
#   - a plain issue-level "no findings" comment (has no commit_id, so it is
#     matched by timestamp against the @codex review trigger instead).
#
# Runs for at most max_wait_seconds per invocation, then exits 2 so the
# caller can decide whether to invoke it again rather than blocking a single
# process indefinitely. Never round-trips captured JSON through a variable
# and `echo` — some shells (zsh's builtin echo, by default) reinterpret
# backslash escapes like the \n inside a review body and corrupt the JSON.
# `printf '%s'` does not have that problem and is used throughout instead.
# `gh api --paginate` alone prints one JSON document per page rather than a
# single merged array, so every paginated call here also passes `--slurp` and
# flattens with `.[][]` in the following jq filter.
#
# Usage:
#   poll-codex-review.sh <owner/repo> <pr_number> <commit_sha> <since_iso8601> \
#     [max_wait_seconds] [interval_seconds]
#
#   owner/repo       e.g. mkuri/dotfiles
#   pr_number        e.g. 122
#   commit_sha       full or short SHA of the commit under review; matched as
#                    a prefix of the review's commit_id
#   since_iso8601    UTC timestamp of the "@codex review" trigger comment,
#                    e.g. 2026-08-05T10:23:05Z (used only for the
#                    issue-comment path)
#   max_wait_seconds default 480 (8 min) -- kept under common single-command
#                    timeouts; re-invoke this script again on exit 2 to keep
#                    polling
#   interval_seconds default 20
#
# Exit codes and stdout:
#   0  review found   -> {"result":"review","review_id":...,"commit_id":...,"findings":[{"id","path","line","body"},...]}
#   1  clean pass      -> {"result":"clean","comment_id":...,"created_at":...,"body":...}
#   2  nothing yet     -> {"result":"timeout","elapsed_seconds":...}

set -uo pipefail

BOT_LOGIN='chatgpt-codex-connector[bot]'

REPO="$1"
PR="$2"
COMMIT="$3"
SINCE="$4"
MAX_WAIT="${5:-480}"
INTERVAL="${6:-20}"

since_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$SINCE" +%s 2>/dev/null || date -u -d "$SINCE" +%s)

# --paginate alone prints one JSON array per page as separate top-level
# documents; --slurp wraps them into a single outer array of pages, so `.[][]`
# below iterates pages then items to get a flat stream regardless of page count.

elapsed=0
while [ "$elapsed" -lt "$MAX_WAIT" ]; do
  reviews=$(gh api --paginate --slurp "repos/$REPO/pulls/$PR/reviews" 2>/dev/null) || reviews="[]"
  # Require the review's own submitted_at to be after the trigger too, not
  # just a commit_id match: re-running "@codex review" without a new commit
  # would otherwise immediately match a stale review from an earlier round.
  match=$(printf '%s' "$reviews" | jq --arg bot "$BOT_LOGIN" --arg commit "$COMMIT" --argjson since "$since_epoch" \
    '[.[][] | select(.user.login == $bot) | select(.commit_id | startswith($commit))
      | select((.submitted_at | fromdateiso8601) > $since)] | .[0] // empty')

  if [ -n "$match" ]; then
    review_id=$(printf '%s' "$match" | jq -r '.id')
    if findings_raw=$(gh api --paginate --slurp "repos/$REPO/pulls/$PR/reviews/$review_id/comments" 2>/dev/null); then
      findings=$(printf '%s' "$findings_raw" | jq -c '[.[][] | {id, path, line, body}]')
      jq -nc --argjson review_id "$review_id" --arg commit "$COMMIT" --argjson findings "${findings:-[]}" \
        '{result: "review", review_id: $review_id, commit_id: $commit, findings: $findings}'
      exit 0
    fi
    # The comment fetch failed (transient network/API error) -- fall through
    # to retry next iteration instead of reporting a false "zero findings".
  fi

  # Require positive evidence of a completed, non-failed clean-pass comment
  # (its "Codex Review" branding) and explicitly reject known skip/failure
  # notices (e.g. an out-of-usage or quota message) rather than treating any
  # bot comment posted after the trigger as a clean result.
  clean=$(gh api --paginate --slurp "repos/$REPO/issues/$PR/comments" 2>/dev/null \
    | jq --arg bot "$BOT_LOGIN" --argjson since "$since_epoch" \
      '[.[][] | select(.user.login == $bot) | select((.created_at | fromdateiso8601) > $since)
        | select(.body | test("codex review"; "i"))
        | select(.body | test("quota|out.of.usage|rate.limit|unable to"; "i") | not)] | .[0] // empty')

  if [ -n "$clean" ]; then
    printf '%s' "$clean" | jq -c '{result: "clean", comment_id: .id, created_at: .created_at, body}'
    exit 1
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

jq -nc --argjson elapsed "$elapsed" '{result: "timeout", elapsed_seconds: $elapsed}'
exit 2
