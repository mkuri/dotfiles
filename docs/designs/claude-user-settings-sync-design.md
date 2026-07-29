# Claude User Settings Synchronization Design

Status: Approved

Date: 2026-07-29

Issue: #101

## Context

The Claude user settings file is currently symlinked from this repository. That
prevents Claude and local tools from persisting machine-specific settings
without modifying the repository-owned source file.

Claude Code reserves managed settings for organization-enforced policy. This
personal dotfiles workflow needs portable defaults without preventing local
configuration.

## Goals

- Keep portable plugin and marketplace choices in dotfiles.
- Preserve hooks, UI preferences, and other machine-specific user settings.
- Migrate the expected legacy symlink without modifying its source.
- Make the migration idempotent and safe for unrelated symlinks.

## Non-goals

- Manage agent-status-bar hooks from this repository.
- Apply organization-level Claude managed settings.
- Remove the legacy settings source during the initial migration.

## Decision

`claude/shared-settings.json` owns only `enabledPlugins` and
`extraKnownMarketplaces`. `claude/sync_settings.py` merges those keyed objects
into the regular local `~/.claude/settings.json` file and preserves all other
keys.

The installer replaces only the expected legacy symlink to
`claude/settings.json`. It reads that source, writes the merged content
atomically to the local settings path, and leaves the source unchanged. The
legacy source remains temporarily so a checkout update cannot leave an existing
symlink without a readable migration source.

## Alternatives

- Continue symlinking the complete settings file: rejected because local state
  and tool-owned settings cannot persist safely.
- Use Claude managed settings: rejected because that mechanism enforces
  organization policy and cannot be overridden by user settings.
- Share hooks with the plugin configuration: rejected because agent-status-bar
  owns hook registration independently.

## Consequences

- Running `agents/setup.sh` migrates the expected legacy symlink on each
  machine.
- Local settings outside the two shared keyed objects remain local.
- A follow-up cleanup may remove `claude/settings.json` and the legacy-symlink
  path after all intended machines have migrated.

## Deferred Work

- Verify the migration on each intended machine before removing the legacy
  source.

## References

- Claude Code settings documentation: https://code.claude.com/docs/en/settings
