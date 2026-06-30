---
description: Stage all changes and commit using the branch-prefix convention
---

Create a git commit for the current changes.

Steps:
1. Run `git status` and `git diff` (staged and unstaged) to see what changed.
2. Determine the branch prefix: take the current branch name (`git rev-parse --abbrev-ref HEAD`) and use the first two hyphen-separated segments (e.g. `feature-123-foo` → `feature-123`). On `master`/`main`, use no prefix.
3. Stage all changes with `git add .` unless the user asked to commit only specific files.
4. Write a concise, imperative commit message. If a prefix was found, format the subject as `<prefix>: <summary>`. Keep the summary under ~72 characters; add a short body only if it genuinely adds value.
5. Commit. Do NOT push unless asked.

If `$ARGUMENTS` is provided, use it as the basis for the commit summary.

Match the existing commit style in `git log` (run `git log --oneline -10` to check).
