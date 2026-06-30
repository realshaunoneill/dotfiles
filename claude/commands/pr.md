---
description: Push the current branch and open a GitHub pull request
---

Open a pull request for the current branch.

Steps:
1. Check state: `git status`, `git branch --show-current`, and `git log <base>..HEAD` (base is usually `master` or `main` — confirm with `git remote show origin` or by checking which exists).
2. If the branch has uncommitted changes, ask whether to commit them first (use the same convention as `/commit`).
3. Push the branch and set upstream if needed: `git push -u origin HEAD`.
4. Summarize the full set of commits on this branch (not just the latest) to write the PR body.
5. Create the PR with `gh pr create`, filling in a clear title and a body with a `## Summary` section and, when relevant, a `## Test plan` section. Use a HEREDOC for the body.
6. Print the PR URL.

If `$ARGUMENTS` is provided, use it to steer the PR title/description.

Do not mark the PR ready or merge it unless explicitly asked.
