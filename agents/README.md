# AI Agent Configuration

`AGENTS.md` is the single source of truth for instructions shared by Claude
Code, Codex, and Antigravity. Product-specific settings remain in their own
directories:

- `claude/`: Claude Code settings, hooks, keybindings, and Claude-only rules
- `antigravity/`: Antigravity hooks and other product-specific configuration
- `codex/`: Add this directory when Codex-specific configuration is needed

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

Antigravity uses the `~/.gemini` paths even though its files use the
`antigravity/` repository directory for clarity.

For isolated testing, set `AGENT_CONFIG_HOME` to use a directory other than the
real home directory:

```sh
AGENT_CONFIG_HOME=/tmp/agent-home ./agents/setup.sh
```
