# Neon + Atlas Best Practices

## Connection URL Composition

Compose the database URL from individual environment variables in `atlas.hcl` using `locals` and `getenv()`. Do not define a separate full `DATABASE_URL` — build it from components to avoid duplication.

```hcl
locals {
  db_url = "postgresql://${getenv("NEON_USER")}:${getenv("NEON_PASSWORD")}@${getenv("NEON_HOST")}/${getenv("NEON_DATABASE")}?sslmode=require"
}
```

Required environment variables:
- `NEON_HOST` — Direct connection endpoint (e.g., `ep-xxx.region.aws.neon.tech`). Must NOT include `-pooler` suffix.
- `NEON_DATABASE` — Database name
- `NEON_USER` — Database user
- `NEON_PASSWORD` — Database password

## Direct vs Pooled Connections

Neon offers two connection types:
- **Direct** (`ep-xxx.region.aws.neon.tech`) — Required for DDL/migration operations. Pooled connections cause timeout and lock issues with schema changes.
- **Pooled** (`ep-xxx-pooler.region.aws.neon.tech`) — For application query traffic only. Never use for migrations.

Always use the direct connection host in `atlas.hcl`.

## Revision Schema

```hcl
migration {
  dir = "file://migrations"
  revisions_schema = "public"
}
```

`revisions_schema = "public"` is recommended. Neon's connection pooler does not reliably propagate `search_path` to Postgres, which breaks Atlas's default behavior of creating a dedicated `atlas_schema_revisions` schema. Explicitly setting `public` bypasses the pooler issue entirely and ensures Atlas can always locate its revision tracking table regardless of connection mode.

## atlas.hcl Template for Neon

```hcl
locals {
  db_url = "postgresql://${getenv("NEON_USER")}:${getenv("NEON_PASSWORD")}@${getenv("NEON_HOST")}/${getenv("NEON_DATABASE")}?sslmode=require"
}

env "neon" {
  src = "file://schema"
  url = local.db_url
  dev = "docker://postgres/17/dev?search_path=public"
  migration {
    dir = "file://migrations"
    revisions_schema = "public"
  }
  diff {
    skip {
      drop_table = true
    }
  }
}
```

Key points:
- `dev` uses local Docker PostgreSQL — never use Neon as the dev database
- `src` points to the HCL schema directory
- `migration.dir` specifies the versioned migrations directory
- `diff.skip.drop_table = true` prevents accidental table drops during migration generation

## Operational Rules

- Always run `atlas migrate apply --env neon --dry-run` before actual apply
- Use versioned workflow: `migrate diff` -> `migrate lint` -> `migrate apply`
- After manual edits to migration files, run `atlas migrate hash --env neon`
