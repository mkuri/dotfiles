# Shared Agent Skills

Research notes and the chosen approach for managing skills that are shared
across **multiple machines, multiple projects, and multiple agents** (Claude
Code, Codex, Antigravity/Gemini). This document is the reference for a later
implementation pass; nothing here is wired into `setup.sh` yet.

## Decision

Use **`gh skill`** (the official GitHub CLI subcommand) as the skill manager.

Rationale:

- We already depend on `gh`, so it adds no new toolchain.
- It targets the open **Agent Skills** spec and installs into the correct
  per-agent directory automatically (`.claude/skills`, `.github/skills`,
  `.agents/skills`), which matches this repo's multi-agent, single-source
  philosophy better than a Claude-only plugin/marketplace.
- It brings package-manager guarantees: immutable tag/release refs, version
  pinning, and content-addressed change detection (local SHA vs. remote).

`skills.sh` (`npx skills add/update/remove`) was the main alternative. It is
lighter to start with and also multi-agent, but it is community-maintained and
its version-pinning story is weaker, so `gh skill` wins for a setup that values
reproducibility.

## Operating model

Two categories of skills, handled differently:

1. **Project-common skills** — shared everywhere. Install at **user scope** so
   they live in the home-level agent config and every project sees them:

   ```sh
   gh skill install OWNER/REPO SKILL --agent claude-code --scope user
   # -> ~/.claude/skills/SKILL
   ```

   These are the ones worth tracking in dotfiles (see Integration below).

2. **Project-specific skills** — install at **project scope**, committed
   directly into that project's own skills directory. These are **not** managed
   by dotfiles:

   ```sh
   gh skill install OWNER/REPO SKILL --agent claude-code --scope project
   # -> ./.claude/skills/SKILL   (commit it to that repo)
   ```

   We deliberately avoid the half-managed middle ground of tracking a skill in
   dotfiles but only wanting it in *some* projects.

## `gh skill` reference

Requires GitHub CLI **v2.90.0+** (public preview, announced 2026-04-16).

Subcommands:

| Command | Purpose |
| --- | --- |
| `gh skill search <query>` | Discover skills across GitHub repos. |
| `gh skill preview OWNER/REPO [SKILL]` | Read a skill *before* installing. GitHub does **not** verify what skills do — prompt-injection risk is real, so preview untrusted skills. |
| `gh skill install OWNER/REPO [SKILL[@VERSION]]` | Install a skill into an agent's skills directory. |
| `gh skill update` | Pull the latest upstream and refresh installed skills. |
| `gh skill pin` | Lock a skill to a tag/commit so bulk `update` runs skip it until deliberately bumped. |
| `gh skill publish` | Publish your own skill back to GitHub, validated against the Agent Skills spec with a repo-security pre-flight. |

Key flags / syntax:

- **Target agent** — `--agent claude-code` (also `copilot`, `cursor`, `codex`,
  `gemini`, …). Determines the destination directory family.
- **Scope** — `--scope user` writes to the home dir (`~/.claude/skills/`,
  available to all projects); `--scope project` writes to the current repo
  (`./.claude/skills/`, committed and team-shared).
- **Version pin** — append `SKILL@VERSION` (a git tag or commit SHA) or use the
  `--pin` flag. Example:

  ```sh
  gh skill install github/awesome-copilot documentation-writer@v1.2.0 \
    --agent claude-code --scope user
  ```

Directory placement (per the Agent Skills spec):

- `.claude/skills/` — Claude Code
- `.github/skills/` — GitHub Copilot
- `.agents/skills/` — generic / other hosts

The home-directory equivalents (e.g. `~/.claude/skills/`) are used for
`--scope user`.

## How this fits the dotfiles (proposal, not yet implemented)

The current dotfiles pattern is: source of truth in the repo, symlinked into
`$HOME` by `agents/setup.sh`. Skills split into two flavors under that model:

- **Third-party project-common skills** — let `gh skill` own the content in
  `~/.claude/skills/` and track only *which* skills + pinned versions in
  dotfiles, e.g. a small install manifest or script under `agents/skills/` that
  `setup.sh` runs (`gh skill install … --scope user` per entry). Symlinking
  these would fight `gh skill`'s content-addressed update mechanism, so we track
  the declaration, not the files.
- **Self-authored project-common skills** (e.g. the existing `atlas` skill) —
  keep the source in the repo (candidate location: `agents/skills/<name>/` or
  the current `claude/optional/skills/<name>/`) and either symlink it into
  `~/.claude/skills/` from `setup.sh` (matches the existing pattern) or share it
  with `gh skill publish`.

Decisions to finalize in the implementation pass:

- Where self-authored skill sources live (`agents/skills/` vs.
  `claude/optional/skills/`), and whether they are symlinked or published.
- The exact manifest/script format for the tracked third-party install list.
- Whether `setup.sh` should run `gh skill install` (needs `gh` + network at
  setup time) or just document the commands.

## Migration notes

- `claude/optional/skills/atlas/` is out of date. Plan: rebuild it with a
  skill-authoring workflow (e.g. the `skill-creator` skill) rather than editing
  in place, then decide its final home per the section above.

## References

- [GitHub Changelog: Manage agent skills with GitHub CLI](https://github.blog/changelog/2026-04-16-manage-agent-skills-with-github-cli/)
- [gh skill install manual](https://cli.github.com/manual/gh_skill_install)
- [gh skill: GitHub CLI Agent Skills Management (Big Hat Group)](https://www.bighatgroup.com/blog/gh-skill-github-cli-agent-skills-management/)
- [GitHub CLI's `gh skill` Command: One Standard to Rule Claude Code, Copilot, Cursor, and Gemini (Groundy)](https://groundy.com/articles/github-clis-gh-skill-command-one-standard-to-rule-claude-code-copilot-cursor/)
- [Explore the .claude directory — Claude Code Docs](https://code.claude.com/docs/en/claude-directory)
- Alternative considered: [Skills for Claude Code via the skills.sh CLI](https://www.skills.sh/agent/claude-code)
