# Global Agent Instructions

## Response Language

### Conversational Language

Match the language the user writes in. When the user communicates in Japanese,
respond and explain in Japanese. Do not drift to English partway through.

This applies especially to implementation and design discussions shown in the
terminal:

- Explanations of what a change does and why
- Trade-off analysis, options, and recommendations
- Debugging reasoning and root-cause explanations
- Summaries of completed work and next steps
- Clarifying questions

Explaining an entire implementation discussion in English when the user is
writing in Japanese is a defect, not a stylistic choice.

### What Stays in English

This conversational rule does not override the English-only requirement for
content committed to git or visible on GitHub:

- Commit messages, pull request and issue text, and review comments
- Source code, code comments, docstrings, and identifiers
- Committed Markdown documents, specifications, READMEs, and design documents

Code snippets, commands, file paths, and technical identifiers stay in their
original form even inside explanations in another language.

## GitHub Conventions

### Language

All content committed to git or visible on GitHub must be in English. This
includes commit messages, pull requests, issues, review feedback, source code
comments, docstrings, Markdown documents, test names, fixtures, and log strings.

Other natural languages belong only in localization sources where the language
is the data, such as Flutter slang `*_ja.g.dart` files, JSON i18n bundles, and
fixtures asserting localized behavior. When referring to localized UI strings
elsewhere, use the i18n key, such as `cancelAssignment.button`, or describe the
concept in English, such as "the recent-payout row", instead of copying the
localized string even when no precise English equivalent exists.

### Issue Management

- `priority/P0`: Production incident or blocker; drop everything
- `priority/P1`: Must-have for the current milestone
- `priority/P2`: Nice-to-have that can be deferred
- `priority/P3`: Low-priority backlog item
- Use prefixed labels such as `priority/`, `area/`, and `type/`.
- Track release due dates with milestones rather than per-issue due dates.

### Commit Messages and Pull Request Titles

Follow Conventional Commits:

```text
<type>(<scope>): <description>
```

Allowed types are `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`,
`perf`, and `style`.

Use a scope when the change targets a specific component or directory, such as
`flutter`, `webapp`, `supabase`, `stripe`, or `edge-functions`. Omit it for
cross-cutting changes or changes without a useful scope. Pull request titles
follow the same convention.

## Branch Protection

Never commit directly to `main` or `master`. Before staging or committing:

1. Check the current branch with `git branch --show-current`.
2. If it is `main` or `master`, stop and create a descriptively named feature
   branch such as `feat/add-login`, `fix/null-pointer`, or `chore/update-deps`.
3. Confirm the branch name with the user before creating it unless the user has
   already approved that exact name.
4. Stage and commit only after moving to the feature branch.

This applies to code, documentation, configuration, and rules without exception.

## Sensitive Files

Never read or display the contents of:

- `.env` or `.env.*`, except `.env.example`
- Gitignored project configuration that may contain secrets or personal data
- Files containing API keys, tokens, credentials, or other secrets
- Service-account JSON files
- `*.jks`, `*.keystore`, `key.properties`, or similar credential files

Check `.gitignore` before inspecting untracked or ignored files. Prefer files
tracked in git. If a file might contain secrets, skip it.

When delegating any file-reading work to another agent, including code review,
PII checks, file audits, and codebase exploration, explicitly include this
instruction in the delegation prompt:

> Do not read `.env`, `.env.*`, `*.jks`, `*.keystore`, `key.properties`, or any
> gitignored file that may contain secrets. Review only files tracked in git. If
> unsure whether a file contains secrets, skip it.

Delegated agents might not inherit the current instructions. Repeat the
sensitive-file restriction in every delegation prompt without exception.

When information from a sensitive file is required:

- Ask the user for the specific value or structure needed.
- Refer to the path without reading its contents.
- Use an example or template file to understand the expected format.

If sensitive data is read accidentally, do not reproduce it. Inform the user and
recommend credential rotation if the data may have been exposed.

## Plan Documents

### Design Documents

- Commit `*-design.md` documents to git, including when created by a
  brainstorming workflow.
- Keep them permanently as records of design decisions.

### Implementation Plans

- Do not commit `*-plan.md` working documents.
- Use them only as working documents during implementation.
- Remove them from the worktree during the development-branch finishing
  workflow.
