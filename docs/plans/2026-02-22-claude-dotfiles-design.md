# Claude Code dotfiles management design

## Goal

Manage `~/.claude` user-configurable files in dotfiles and sync via symlinks.

## Target files

| Source (dotfiles) | Destination | Symlink type |
|---|---|---|
| `claude/settings.json` | `~/.claude/settings.json` | File |
| `claude/keybindings.json` | `~/.claude/keybindings.json` | File |
| `claude/rules/` | `~/.claude/rules/` | Directory (existing) |
| `claude/hooks/` | `~/.claude/hooks/` | Directory |
| `claude/setup.sh` | N/A (executed directly) | N/A |

## Out of scope

- `plugins/`, `config/`, `session-env/`, `debug/`, `backups/`, `tasks/`, `todos/`, `projects/`, `history.jsonl`, `telemetry/`, `cache/`, `paste-cache/`, `file-history/` (auto-generated)
- `notify-on-stop.sh` Linux support
- Integration with main `setup-dotfiles.sh`

## Directory structure

```
claude/
├── rules/                    # Existing (already symlinked)
│   └── sub-agent-model-policy.md
├── hooks/                    # New
│   └── notify-on-stop.sh    # Moved from ~/.claude/hooks/
├── settings.json             # New (moved from ~/.claude/)
├── keybindings.json          # New (empty JSON {})
└── setup.sh                  # New: symlink setup script
```

## setup.sh behavior

- Check if symlink/file already exists before creating
- Skip with message if target already exists (same pattern as `setup-dotfiles.sh`)
- Create `~/.claude` directory if it doesn't exist
- POSIX-compatible bash for macOS/Linux

## Decisions

- Full sharing across machines (macOS/Linux), OS differences handled inside config files
- Directory-level symlinks for `rules/` and `hooks/` (user-managed directories)
- File-level symlinks for `settings.json` and `keybindings.json` (files in mixed auto-generated directory)
- Separate setup script (`claude/setup.sh`), not merged into `setup-dotfiles.sh`
