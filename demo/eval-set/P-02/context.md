# Case P-02 context

- Repository: northwind-shipments-api
- Pull request: 158 (the merged fix for issue 156)
- Commit before: case/P-02 (the commit before pull request 158, same as pr-153-merged)
- Merged ref: pr-158-merged
- Test added: test_search_with_apostrophe
- Test files to copy in: tests/test_shipments.py
- Suite command: `pytest -q`
- Case branch: case/P-02
- Type: Capability
- Should Claude ask first? No

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-02 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-02 \
  --request ~/nw-foundation/eval-set/P-02/request.md \
  --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
  --reference-repo ~/nw-foundation/northwind-shipments-api --reference-ref pr-158-merged \
  --reference-files tests/test_shipments.py
```

## How to grade

Automatable grader: the merged pull request's tests/test_shipments.py is copied into each worktree, then
`pytest -q` runs. "What we noticed" says "Reference tests: pass" or "fail". The tests cannot tell placeholders
from quotes escaped by hand, so read the .diff: the search values must reach SQL through ? placeholders.
