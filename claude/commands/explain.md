---
description: Explain the current diff or a given file in plain language
---

Explain code in plain, approachable language.

Target:
- If `$ARGUMENTS` names a file or path, explain that file.
- Otherwise, explain the current working-tree changes (`git diff` plus `git diff --staged`). If there are no changes, explain the most recent commit (`git show HEAD`).

Produce:
1. A one-sentence high-level summary of what the code/change does.
2. A short walkthrough of the key parts, referencing `file:line` so they're clickable.
3. Anything noteworthy: side effects, edge cases, risks, or assumptions.

Keep it concise and skip the obvious. Do not modify any files — this is read-only.
