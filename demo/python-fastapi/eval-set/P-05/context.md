# Case P-05 context

- Repository: northwind-shipments-api
- Pull request: 170 (feat: export shipments as CSV), open; the staff engineer's review blocked it
- Case branch: case/P-05 (the branch of pull request 170; its last commit is the change)
- Commit before: pr-163-merged (the parent of the pull request's commit)
- Merged ref: none (not merged)
- Reference: reference.md, the staff engineer's accepted review
- Suite command: none (review case)
- Type: Capability
- Should Claude ask first? No

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-05 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-05 \
  --request ~/nw-foundation/eval-set/P-05/request.md \
  --allow "Bash(git log *),Bash(git show *),Bash(git diff *),Bash(git branch *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs
```

## How to grade

No automatable grader: "What we noticed" says "Review case: grade the reply (.md) against note.md". Read the
run's .md: it must flag the export route for missing require_admin, with file and line (compare reference.md).
A quick check is that the reply names app/routes/admin.py and require_admin. The .diff should be empty.
