# Sensitive File Policy

## Never read or display contents of:

- `.env`, `.env.*` files (except `.env.example`)
- Project config files that are gitignored and may contain secrets or personal data (check `.gitignore` first)
- Files containing API keys, secrets, tokens, or credentials
- Files listed in `.gitignore` that may contain sensitive data
- Service account JSON files
- Keystore files (`.jks`, `.keystore`)
- `key.properties` or similar credential config files

## Subagents and Agents

**CRITICAL: When dispatching subagents (Agent tool) for ANY task that involves reading files — code review, PII checks, file audits, codebase exploration — you MUST include the following instruction in the prompt:**

> Do NOT read any of these files: .env, .env.*, *.jks, *.keystore, key.properties, or any file listed in .gitignore that may contain secrets. Only review files tracked in git. If unsure whether a file contains secrets, skip it.

Subagents do NOT inherit these rules. Every subagent prompt must explicitly prohibit reading sensitive files. There are no exceptions.

## When you need information from these files:

- Ask the user what specific values or structure you need
- Reference the file path without reading its contents
- Use `.example` or template files to understand the expected format

## If you accidentally read a sensitive file:

- Do NOT output its contents
- Immediately inform the user that you encountered sensitive data
- Suggest credential rotation if contents were exposed
