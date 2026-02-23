# Branch Protection

## Main/Master Branch Rule

NEVER commit directly to main or master branches. Before any git add or git commit:

1. Check the current branch: `git branch --show-current`
2. If on main or master:
   - STOP — do not stage or commit any files
   - Create a new feature branch first: `git checkout -b <branch-name>`
   - Use a descriptive branch name (e.g., `feat/add-login`, `fix/null-pointer`, `chore/update-deps`)
   - Ask the user to confirm the branch name before creating it
3. Only then proceed with staging and committing

This applies to ALL changes — code, docs, config, rules. No exceptions.
