# Sensitive File Policy

## Never read or display contents of:

- `.env`, `.env.*` files (except `.env.example`)
- Files containing API keys, secrets, tokens, or credentials
- Files listed in `.gitignore` that may contain sensitive data
- Service account JSON files
- Keystore files (`.jks`, `.keystore`)
- `key.properties` or similar credential config files

## When you need information from these files:

- Ask the user what specific values or structure you need
- Reference the file path without reading its contents
- Use `.example` or template files to understand the expected format

## If you accidentally read a sensitive file:

- Do NOT output its contents
- Immediately inform the user that you encountered sensitive data
- Suggest credential rotation if contents were exposed
