# Git Quality Gates Template

This template adds local hooks and GitHub Actions checks for repository rules
that can be evaluated mechanically. It complements, but does not replace,
agent instructions: hooks run only where installed and cannot encode the
reasoning, exceptions, or follow-up work in `AGENTS.md`.

## Included gates

- Conventional Commit messages, using the allowed type set in
  `commitlint.config.cjs`.
- Direct commits to `main` and `master`.
- Private keys, probable secrets, and the sensitive or temporary path patterns
  in `scripts/check_forbidden_paths.py`.
- Added files over 500 KiB.
- The same pre-commit hooks and commit-message linting in GitHub Actions.

## Adopt the template

Copy the template contents into the root of the target repository. Keep the
relative locations shown below because `.pre-commit-config.yaml` invokes the
path checker from `scripts/`.

```text
.pre-commit-config.yaml
commitlint.config.cjs
scripts/check_forbidden_paths.py
.github/workflows/quality-gates.yml
```

Install the local dependencies and hooks:

```sh
npm install --save-dev @commitlint/cli
pre-commit install --install-hooks
pre-commit run --all-files
```

The committed `.pre-commit-config.yaml` installs both `pre-commit` and
`commit-msg` hooks. The `commitlint` hook uses the repository-local
`@commitlint/cli`, so do not use a global installation.

## Maintain the configuration

The tool configuration is the source of truth for the exact commit types and
forbidden-path patterns. Update `commitlint.config.cjs` or
`scripts/check_forbidden_paths.py` when a project has an approved exception,
then run `pre-commit autoupdate` deliberately and review its changes before
committing them.

Do not use this template to encode judgement-based guidance such as language,
architecture, security response, or pull request workflow. Keep that guidance
in `AGENTS.md`.
