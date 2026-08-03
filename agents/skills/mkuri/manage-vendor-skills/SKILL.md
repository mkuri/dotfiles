---
name: manage-vendor-skills
description: Install, update, vendor, or adapt external agent skills in this dotfiles repository. Use whenever adding a third-party skill under agents/skills/vendor/, running gh skill install/update, deciding whether a skill belongs in vendor/ or mkuri/, or recording a source in the vendor registry. Enforces license compliance for public redistribution.
---

# Manage vendor and owned skills in dotfiles

This dotfiles repository is **public** (`github.com/mkuri/dotfiles`), and
`agents/setup.sh` links every skill under `agents/skills/{mkuri,vendor}/` into
`~/.claude/skills/` and `~/.codex/skills/` for **all** repositories. Committing
a skill here therefore both redistributes it publicly and activates it globally.
Follow these rules before pushing.

## Layout and ownership

| Directory | Meaning | May be edited? |
| --- | --- | --- |
| `agents/skills/vendor/<skill>/` | Externally sourced skill, kept pristine and tracked to an upstream revision with `gh skill`. | **No.** Byte-for-byte upstream. |
| `agents/skills/mkuri/<skill>/` | Skill authored or owned in this repository. | Yes. |

The boundary maps to the harness `Adopt` vs `Adapt` decision: **Adopt** an
unchanged upstream skill in `vendor/`; **Adapt** it by copying the workflow into
an owned `mkuri/` skill. Never do both for the same content.

## Install and update

Run from the `agents/` directory:

```sh
gh skill install <owner>/<repo> <skill-path> --dir skills/vendor
gh skill update --dir skills/vendor --all
gh skill publish skills/mkuri --dry-run   # validate owned skills before release
```

`gh skill install` writes provenance into the skill's `SKILL.md` frontmatter
(`github-repo`, `github-path`, `github-ref`, `github-tree-sha`). That is the pin;
do not hand-edit it.

## License compliance (required before pushing to a public repo)

`gh skill install` does **not** copy the upstream license, so a vendored skill is
not redistribution-compliant on its own. Before committing:

1. Check the upstream license:
   `gh api repos/<owner>/<repo>/license --jq '.license.spdx_id'`.
2. **MIT / BSD / Apache-2.0 (and similar permissive):** redistribution is
   allowed. Copy the upstream `LICENSE` into the vendored skill directory
   (`agents/skills/vendor/<skill>/LICENSE`). For Apache-2.0 also copy `NOTICE`
   if present. A link in the frontmatter is **not** a substitute for the license
   text and copyright notice.
3. **No license, or a proprietary/non-redistributable license:** do **not**
   commit a copy to this public repo. Instead keep it local (gitignore it) or
   install it per machine from `agents/setup.sh` at setup time. Record the
   decision in the registry.
4. If you ever modify vendored content, you have adapted it — move it to
   `mkuri/`, and for Apache-2.0 state the changes made.

## Never modify vendor content

Editing a `vendor/<skill>/` file breaks the `gh skill update --all` diff against
upstream. If you need to change a description scope, tighten a trigger, or apply
product policy, copy the workflow into an owned `mkuri/<skill>/` skill and adapt
it there. Keep `vendor/` byte-for-byte upstream (the added `LICENSE`/`NOTICE`
files are the only allowed additions).

## Scope descriptions to prevent misfiring

Because every installed skill's description sits in every session's context,
write the description with its context precondition (for example, "when editing
native Android files under `android/`"), not just the technology name. This is
what makes a globally installed, stack-specific skill safe in unrelated repos.
The skill body is only read on trigger, so scoping lives in the description.

## Record every source in the registry

Update `agents/skills/vendor/REGISTRY.md` in the same change. For each source
record: upstream URL, license (SPDX id), selected skill folders, pinned
`github-tree-sha`, whether a `LICENSE` file is vendored, review date and
reviewer, whether any bundled scripts / MCP config / hooks / `allowed-tools` are
approved or rejected, and any product policy that overrides the skill. The
frontmatter holds the pin; the registry holds license and review state.

## Checklist before committing a vendored skill

- [ ] Installed with `gh skill install ... --dir skills/vendor` (provenance in frontmatter).
- [ ] Upstream license checked; permissive → `LICENSE` copied into the skill dir; non-permissive → not committed.
- [ ] `vendor/` content left unmodified (only `LICENSE`/`NOTICE` added).
- [ ] Adaptations, if any, live in `mkuri/` instead.
- [ ] Description scoped so it will not misfire in unrelated repositories.
- [ ] `REGISTRY.md` entry added or updated.
- [ ] `agents/setup.sh` run to confirm the skill links cleanly.
