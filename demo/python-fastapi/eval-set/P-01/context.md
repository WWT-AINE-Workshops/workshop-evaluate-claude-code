# Case P-01 context

- Repository: northwind-shipments-api
- Pull request: 151 (the merged fix for issue 142)
- Commit before: issue-142-base
- Merged ref: pr-151-merged
- Test added: test_get_shipment_without_carrier
- Test files to copy in: tests/test_shipments.py
- Suite command: `pytest -q`
- Case branch: case/P-01
- Type: Capability
- Should Claude ask first? No

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-01 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-01 \
  --request ~/nw-foundation/eval-set/P-01/request.md \
  --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
  --reference-repo ~/nw-foundation/northwind-shipments-api --reference-ref pr-151-merged \
  --reference-files tests/test_shipments.py
```

## How to grade

Automatable grader: the merged pull request's tests/test_shipments.py is copied into each worktree, then
`pytest -q` runs. "What we noticed" says "Reference tests: pass" or "fail". Then read the run's .diff against
note.md: weak.diff (pull request 149) passes its own edited test but fails the merged ones.
