# Branch Protection Rule Design

**Date**: 2026-02-23
**Status**: Approved

## Problem

Claude Code commits directly to main/master branch without checking the current branch first. The user has to manually reject git add operations and instruct Claude Code to create a feature branch, which is repetitive and error-prone.

## Root Cause

- Superpowers skills (`executing-plans`, `subagent-driven-development`) have "red flag" warnings about main branch but no programmatic enforcement
- The `/commit` flow and general git operations don't check the current branch
- Worktree-based isolation is the assumed mechanism, but the user doesn't use worktrees (Flutter/Supabase environments are difficult to test in worktrees)

## Solution

Add a global Claude Code rule file at `claude/rules/branch-protection.md` that instructs Claude Code to:

1. Check the current branch before any git add/commit
2. If on main/master, stop and create a feature branch first
3. Ask the user to confirm the branch name before creating it

## Scope

- All projects (global rule via dotfiles)
- All changes (code, docs, config, rules — no exceptions)

## Workflow

1. User requests changes
2. Claude Code implements changes
3. Before staging/committing, Claude Code runs `git branch --show-current`
4. If on main/master: propose a branch name, confirm with user, create branch
5. If already on a feature branch: proceed with commit
