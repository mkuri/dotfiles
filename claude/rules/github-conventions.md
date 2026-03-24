# GitHub Conventions

## Language

All GitHub Issues, Pull Requests (title and body), and commit messages MUST be written in English. This applies to all content visible on GitHub, including comments and review feedback.

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
