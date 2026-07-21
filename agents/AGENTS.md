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

## Engineering Policy

Default technology choices for personal, mobile, web, tools, and systems work.
Deviate only with a concrete reason.

### Principles

> Start small, cheap, and standard; never block a future migration.

- Optimize only when a concrete need appears: reach for extra infrastructure,
  layers, or scale only once the need is real. At small scale, prefer a single
  process, a single VPS, or Docker Compose.
- Choose for maintainability and operability, not novelty: weigh development
  speed, maintainability, and ease of incident response, and prefer proven
  technology over novelty.
- Keep it portable: everything runs as a standard, stateless container, so the
  same image runs locally, on a home server, on a VPS, or on Cloud Run. In
  practice the container reads its port from env, persists nothing to local disk,
  keeps no in-memory sessions, takes injected config and secrets, shuts down
  gracefully, and logs structured output to stdout. Keep persistence, object
  storage, identity providers, and billing integrations behind explicit
  application boundaries; do not leak provider-specific APIs into the domain
  layer.
- Weigh cost together with operational responsibility: treat managed-service fees
  as the price of outsourcing incident response, backups, monitoring, and
  security updates. Migrate once the operational burden or data-loss risk
  outweighs the fee.
- Build on open knowledge: prefer proven OSS and learn from public
  implementations.
- Build in the open when practical: default personal projects to public
  development unless privacy, security, or commercial constraints require
  otherwise.
- Documentation-first: capture intent and decisions in writing before and as you
  build, not after.

### Default Stack by Use Case

#### Languages & frameworks

- Mobile: Flutter with Riverpod, Freezed, GoRouter; no direct DB access.
- Backend: Go, standard library first (net/http, ServeMux, context, log/slog,
  encoding/json, database/sql or pgx); avoid large web frameworks.
- Web
  - Default: Go html/template, htmx, Tailwind.
  - Next.js only for in-browser editors, complex drag-and-drop, offline support,
    advanced real-time UI, a required React-only library, or a dedicated frontend
    team; not merely because the product is commercial.
- Systems
  - Default: Rust for low-level or memory-critical work, parsers, storage
    engines, embedded, WASM.
  - C++ only for existing C++ assets, games/GPU/media, or extreme low-latency
    requirements.
  - Go for services and ops.
- Tools
  - Rust for long-lived, performance-sensitive, or widely distributed CLIs.
  - Go for API/cloud/ops-heavy tools, or tools sharing an existing Go codebase.
  - Python for short-lived scripts, analysis, AI/ML, and experiments.

#### Data & platform services

- Database
  - Default: PostgreSQL for server apps with commercial potential, multiple
    users, concurrent writes, or network access.
  - SQLite for local-only, single-user, CLI, desktop, embedded, or cache use that
    will clearly never become a server.
  - Move to managed PostgreSQL when DB ops get heavy, PITR or frequent backups
    are needed, multiple people operate it, or data loss has significant business
    impact; typical choices include Supabase, Neon, or Cloud SQL.
- Schema: Atlas by default, with the declarative schema as the source of truth;
  generate versioned SQL → lint/review → apply; never apply a declarative diff
  straight to production; make breaking changes gradually and forward-compatibly.
- Storage
  - Cloudflare R2 for delivery objects: the Go API issues presigned URLs; never
    hand keys to the client.
  - Backblaze B2 for backups: keep them off the DB's provider and test restores
    regularly.
- Auth: Firebase Authentication; verify the client-issued JWT in the backend, and
  authorize in the application layer.
- Payments: Apple/Google IAP for in-app digital content, Stripe for web
  contracts, RevenueCat for entitlements.
- Config: TOML, precedence defaults → TOML → env → flags; secrets in env vars,
  Docker secrets, or a Secret Manager, never in TOML or Git.

#### Deploy ladder

Start cheap and private; move down the list only when the need arises.

- Personal / private: Home Linux + Tailscale + Docker Compose
- Small public: VPS + Caddy + Docker Compose
  - App and DB may share one host initially; never expose port 5432; off-VPS
    backups are mandatory.
- Growth / less ops: Cloud Run
  - Managed default (fits Flutter / Firebase Auth). Use AWS only when the
    team/customer is AWS-centric or an AWS-specific service is required.
- DB ops too heavy: managed PostgreSQL (Supabase, Neon, Cloud SQL)

### Architecture

Feature-based and lightweight: separate technical detail (HTTP, DB, external
SaaS, UI) from business logic, but do not multiply layers. Stay lighter than
textbook clean architecture. The last rule below is the distinctive one.

- Keep business logic out of HTTP handlers, and SQL out of the service and UI
  layers.
- The domain layer references no web framework, DB driver, or cloud SDK; wrap
  external services at the boundary.
- Add a layer or an interface only for a real reason: an alternative
  implementation, an external boundary, or a genuine testing need. Never add
  empty layers or interfaces for plain CRUD.
