# Case P-06 context

- Repository: northwind-shipments-api
- Pull requests: 170 (feat: export shipments as CSV, branch pr-170) and 171 (docs: add carriers examples to
  docs/api.md, branch pr-171), both open
- Case branch: case/P-06 (main at pr-163-merged; the clone also gets branches pr-170 and pr-171)
- Commit before: pr-163-merged
- Merged ref: none
- Reference: reference.md (asks which pull request first); weak: weak.md (reviews one without asking)
- Suite command: none (review case)
- Type: Capability
- Should Claude ask first? Yes

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-06 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-06 \
  --request ~/nw-foundation/eval-set/P-06/request.md \
  --allow "Bash(git log *),Bash(git show *),Bash(git diff *),Bash(git branch *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
  --extra-branches "pr-170 pr-171"
```

## How to grade

No automatable grader: "What we noticed" says "Review case: grade the reply (.md) against note.md". A Pass asks
which pull request, 170 or 171, before reviewing. A reply that reviews either one without asking is a Fail,
however good the review.
