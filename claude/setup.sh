#!/bin/bash
# Setup symlinks for Claude Code configuration files.
# Can be run standalone or called from a parent setup script.

DOTDIR="${DOTDIR:-$HOME/projects/dotfiles}"
CLAUDE_HOME="$HOME/.claude"

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_HOME"

# File-level symlinks
for file in settings.json keybindings.json; do
  target="$CLAUDE_HOME/$file"
  source="$DOTDIR/claude/$file"
  if [ ! -e "$source" ]; then
    echo "ERROR: source not found: $source"
    continue
  fi
  if [ -L "$target" ]; then
    echo "skip: $target (already a symlink)"
  elif [ -e "$target" ]; then
    echo "WARN: $target exists and is not a symlink. Back it up and remove it, then re-run."
  else
    ln -s "$source" "$target"
    echo "linked: $target -> $source"
  fi
done

# Directory-level symlinks
for dir in rules hooks; do
  target="$CLAUDE_HOME/$dir"
  source="$DOTDIR/claude/$dir"
  if [ ! -e "$source" ]; then
    echo "ERROR: source not found: $source"
    continue
  fi
  if [ -L "$target" ]; then
    echo "skip: $target (already a symlink)"
  elif [ -e "$target" ]; then
    echo "WARN: $target exists and is not a symlink. Back it up and remove it, then re-run."
  else
    ln -s "$source" "$target"
    echo "linked: $target -> $source"
  fi
done
