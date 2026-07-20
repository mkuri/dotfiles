#!/bin/sh
# Install shared and tool-specific AI agent configuration with symlinks.

set -u

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
DOTFILES_DIR=$(dirname -- "$SCRIPT_DIR")
TARGET_HOME=${AGENT_CONFIG_HOME:-$HOME}
setup_status=0

ensure_dir() {
  directory=$1
  if [ -d "$directory" ]; then
    return
  fi
  if [ -e "$directory" ] || [ -L "$directory" ]; then
    echo "ERROR: directory path is occupied: $directory" >&2
    return 1
  fi
  mkdir -p "$directory"
  echo "created: $directory"
}

link_path() {
  source_path=$1
  target_path=$2

  if [ ! -e "$source_path" ]; then
    echo "ERROR: source not found: $source_path" >&2
    return 1
  fi

  ensure_dir "$(dirname -- "$target_path")" || return 1

  if [ -L "$target_path" ]; then
    current_source=$(readlink "$target_path")
    if [ "$current_source" = "$source_path" ]; then
      echo "skip: $target_path (already linked)"
      return
    fi
    echo "WARN: $target_path links to $current_source; expected $source_path" >&2
    return 1
  fi

  if [ -e "$target_path" ]; then
    echo "WARN: $target_path exists and is not a symlink; leaving it unchanged" >&2
    return 1
  fi

  ln -s "$source_path" "$target_path"
  echo "linked: $target_path -> $source_path"
}

prepare_claude_rules_dir() {
  rules_dir="$TARGET_HOME/.claude/rules"
  legacy_source="$DOTFILES_DIR/claude/rules"

  if [ -L "$rules_dir" ]; then
    current_source=$(readlink "$rules_dir")
    if [ "$current_source" != "$legacy_source" ]; then
      echo "ERROR: $rules_dir links to $current_source; expected $legacy_source" >&2
      return 1
    fi
    rm "$rules_dir"
    mkdir -p "$rules_dir"
    echo "migrated: $rules_dir (legacy directory symlink replaced)"
    return
  fi

  ensure_dir "$rules_dir"
}

# Shared instructions.
link_path "$DOTFILES_DIR/agents/AGENTS.md" "$TARGET_HOME/.codex/AGENTS.md" || setup_status=1
if prepare_claude_rules_dir; then
  link_path "$DOTFILES_DIR/agents/AGENTS.md" \
    "$TARGET_HOME/.claude/rules/common.md" || setup_status=1
  link_path "$DOTFILES_DIR/claude/rules/sub-agent-model-policy.md" \
    "$TARGET_HOME/.claude/rules/sub-agent-model-policy.md" || setup_status=1
else
  setup_status=1
fi
link_path "$DOTFILES_DIR/agents/AGENTS.md" "$TARGET_HOME/.gemini/GEMINI.md" || setup_status=1

# Claude Code-specific configuration.
link_path "$DOTFILES_DIR/claude/settings.json" "$TARGET_HOME/.claude/settings.json" || setup_status=1
link_path "$DOTFILES_DIR/claude/keybindings.json" "$TARGET_HOME/.claude/keybindings.json" || setup_status=1
link_path "$DOTFILES_DIR/claude/hooks" "$TARGET_HOME/.claude/hooks" || setup_status=1

# Antigravity-specific configuration. Antigravity stores its files under
# ~/.gemini even though the repository directory uses the product name.
link_path "$DOTFILES_DIR/antigravity/config/hooks.json" \
  "$TARGET_HOME/.gemini/config/hooks.json" || setup_status=1

exit "$setup_status"
