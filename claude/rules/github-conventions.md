# GitHub Conventions

## Language

All content committed to git or visible on GitHub MUST be in English. This applies to every form of text in the repo or on GitHub, including:

- Commit messages (subject and body)
- PR/issue titles, bodies, comments, and review feedback
- Source code comments and docstrings
- Committed Markdown documents (specs, READMEs, ADRs, design docs)
- Test names, fixtures, log strings, and any other in-repo text

The only place Japanese (or any other natural language) belongs is in localization source files where the language IS the data — e.g. Flutter slang `*_ja.g.dart`, JSON i18n bundles, fixtures asserting i18n behavior. Outside those files, default to English without exception.

When referring to Japanese UI strings in commits, comments, or docs, name the i18n key (e.g. `cancelAssignment.button`) or describe the action in English ("the recent-payout row") — do not paste the Japanese string itself, even when no precise English equivalent exists; describe the concept instead.

## Issue Management

### Priority Labels

- `priority/P0` — Production incident or blocker, drop everything
- `priority/P1` — Must-have for current milestone
- `priority/P2` — Nice-to-have, can be deferred
- `priority/P3` — Low priority, backlog

### Label Naming Convention

Use prefixed labels: `priority/`, `area/`, `type/`

### Milestones

Use milestones to track release targets. Issue due dates are managed via milestone due dates, not per-issue.

## Commit Messages

Follow the Conventional Commits format:

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`, `style`

### Scope

Add a scope in parentheses when the change targets a specific area of the project. Use the component or directory name (e.g., `flutter`, `webapp`, `supabase`, `stripe`, `edge-functions`). Omit scope when the change is cross-cutting or doesn't fit a single area.

### PR Titles

PR titles follow the same format as commit messages.
