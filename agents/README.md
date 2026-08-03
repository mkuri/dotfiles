# AI Agent Configuration

`AGENTS.md` is the single source of truth for instructions shared by Claude
Code, Codex, and Antigravity. Product-specific settings remain in their own
directories:

- `agents/skills/mkuri/`: shared skills authored in this repository
- `agents/skills/vendor/`: externally sourced shared skills managed with `gh skill`
- `claude/`: Claude Code shared settings, hooks, keybindings, and Claude-only rules
- `antigravity/`: Antigravity hooks and other product-specific configuration
- `codex/`: Codex permissions and configuration synchronizer

Run the installer from anywhere:

```sh
./agents/setup.sh
```

The installer creates these links without replacing unrelated existing files:

```text
~/.claude/CLAUDE.md                          -> agents/AGENTS.md
~/.claude/skills/<skill>                     -> agents/skills/{mkuri,vendor}/<skill>
~/.claude/rules/sub-agent-model-policy.md    -> claude/rules/sub-agent-model-policy.md
~/.claude/keybindings.json                   -> claude/keybindings.json
~/.claude/hooks                              -> claude/hooks
~/.codex/AGENTS.md                           -> agents/AGENTS.md
~/.codex/skills/<skill>                      -> agents/skills/{mkuri,vendor}/<skill>
~/.gemini/GEMINI.md                          -> agents/AGENTS.md
~/.gemini/config/hooks.json                  -> antigravity/config/hooks.json
```

`~/.codex/config.toml` remains a regular local file because Codex updates
machine-specific and dynamic state in it. The installer idempotently merges
only the settings shared from `codex/shared-config.toml`, preserving every
unmanaged key and avoiding a rewrite when the shared values already match.
It also migrates the legacy dotfiles symlink to a regular file without changing
the symlink source.

Check for drift without changing the local file:

```sh
python3 codex/sync_config.py --check
```

Apply the shared settings directly:

```sh
python3 codex/sync_config.py --apply
```

`~/.claude/settings.json` is also kept as a regular local file. The installer
merges only the portable plugin and marketplace settings from
`claude/shared-settings.json`, preserving hooks, UI preferences, and every
other local setting. It migrates the expected legacy dotfiles symlink without
changing its source. The legacy `claude/settings.json` remains temporarily as
the migration source and will be removed in a later cleanup.

Check or apply the shared Claude settings directly:

```sh
python3 claude/sync_settings.py --check
python3 claude/sync_settings.py --apply
```

Antigravity uses the `~/.gemini` paths even though its files use the
`antigravity/` repository directory for clarity.

## Shared skills

`agents/setup.sh` automatically installs every skill found one or two directory
levels below `agents/skills/` for both Codex and Claude Code. Use `mkuri/` for
skills maintained in this repository and `vendor/` for externally sourced
skills.

Install and update vendor skills from the `agents/` directory:

```sh
gh skill install <owner>/<repo> <skill-path> --dir skills/vendor
gh skill update --dir skills/vendor --all
```

Validate the repository-authored skills before publishing a release:

```sh
gh skill publish skills/mkuri --dry-run
```

This repository is public and installs skills globally, so vendoring a
third-party skill is both a public redistribution and a global activation.
Before pushing a vendored skill, follow the
[`manage-vendor-skills`](skills/mkuri/manage-vendor-skills/SKILL.md) workflow:
check and vendor the upstream license, keep `vendor/` content unmodified (adapt
into `mkuri/` instead), scope the description so it does not misfire in
unrelated repositories, and record the source in
[`skills/vendor/REGISTRY.md`](skills/vendor/REGISTRY.md).

For isolated testing, set `AGENT_CONFIG_HOME` to use a directory other than the
real home directory:

```sh
AGENT_CONFIG_HOME=/tmp/agent-home ./agents/setup.sh
```

## Codex permission policy

The Codex profile allows routine workspace edits, public network access, live
web search, and local development endpoints without approval. It denies access
to common secret-file patterns and credential directories.

Connector permissions are managed separately from these local files. Use the
global **Any changes** setting so connector reads run automatically while
external writes require approval. Browser reads and localhost implementation
checks can run automatically; submitting data or changing an external site
should remain interactive.
