# AI Agent Configuration

`AGENTS.md` is the single source of truth for instructions shared by Claude
Code, Codex, and Antigravity. Product-specific settings remain in their own
directories:

- `claude/`: Claude Code settings, hooks, keybindings, and Claude-only rules
- `antigravity/`: Antigravity hooks and other product-specific configuration
- `codex/`: Codex permissions and configuration synchronizer

Run the installer from anywhere:

```sh
./agents/setup.sh
```

The installer creates these links without replacing unrelated existing files:

```text
~/.claude/CLAUDE.md                          -> agents/AGENTS.md
~/.claude/rules/sub-agent-model-policy.md    -> claude/rules/sub-agent-model-policy.md
~/.claude/settings.json                      -> claude/settings.json
~/.claude/keybindings.json                   -> claude/keybindings.json
~/.claude/hooks                              -> claude/hooks
~/.codex/AGENTS.md                           -> agents/AGENTS.md
~/.gemini/GEMINI.md                          -> agents/AGENTS.md
~/.gemini/config/hooks.json                  -> antigravity/config/hooks.json
```

`~/.codex/config.toml` remains a regular local file because Codex updates
machine-specific and dynamic state in it. The installer idempotently merges
only the settings owned by `codex/managed-config.toml`, preserving every
unmanaged key and avoiding a rewrite when the managed values already match.
It also migrates the legacy dotfiles symlink to a regular file without changing
the symlink source.

Check for drift without changing the local file:

```sh
python3 codex/sync_config.py --check
```

Apply the managed settings directly:

```sh
python3 codex/sync_config.py --apply
```

Antigravity uses the `~/.gemini` paths even though its files use the
`antigravity/` repository directory for clarity.

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
