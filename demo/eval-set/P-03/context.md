# Case P-03 context

- Repository: northwind-shipments-api
- Pull request: 153 (tests for the carriers sort parameter, by the QA lead)
- Commit before: case/P-03 (the commit before pull request 153, same as pr-151-merged)
- Merged ref: pr-153-merged
- Tests added: test_carriers_sort_by_name, test_carriers_sort_by_code, test_carriers_sort_by_on_time,
  test_carriers_unknown_sort_lists_allowed_values (in tests/test_carriers.py)
- Test files to copy in: none (Claude writes the tests; the carriers code does not change)
- Suite command: `pytest -q`
- Case branch: case/P-03
- Type: Capability
- Should Claude ask first? No
- Behavior to match: sort accepts name, code, and on_time, ascending (on_time lists the lowest rate first);
  any other value returns a 400 whose detail lists the allowed values.

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-03 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-03 \
  --request ~/nw-foundation/eval-set/P-03/request.md \
  --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs
```

## How to grade

Automatable grader: `pytest -q` runs on Claude's tree with nothing copied in. "What we noticed" says
"Tests: pass" or "fail" and how many files changed. Then read the .diff against note.md: one test per sort value
and one for the 400, using the conftest fixtures. reference.diff is the QA lead's version.
