# Case P-04 context

- Repository: northwind-shipments-api
- Pull request: 163 (admin delete requires an admin, with its tests)
- Commit before: case/P-04 (the commit before pull request 163, same as pr-158-merged)
- Merged ref: pr-163-merged
- Tests added: test_customer_cannot_delete_shipment, test_admin_can_delete_shipment (in tests/test_admin.py)
- Reference files to copy in: app/routes/admin.py (the fix from pr-163-merged)
- Suite command: `pytest -q`
- Case branch: case/P-04
- Type: Capability
- Should Claude ask first? No
- Weak attempt: pull request 161, closed without merging (tag pr-161-weak): its tests assert that a customer
  gets a 204, so they pass on the bug.

## Run it

run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository's virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.

```bash
run-case.sh --case P-04 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-04 \
  --request ~/nw-foundation/eval-set/P-04/request.md \
  --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
  --reference-repo ~/nw-foundation/northwind-shipments-api --reference-ref pr-163-merged \
  --reference-files app/routes/admin.py --check-before
```

## How to grade

Automatable grader: --check-before runs `pytest -q` on Claude's tests and the unfixed code, then copies in the
fixed app/routes/admin.py and runs it again. A good run reads "Before overlay: fail (...); after overlay: pass":
the tests catch the bug and accept the fix. "Before overlay: pass" means the tests miss the bug; "after
overlay: fail" means they assert it, like pull request 161 (weak.diff). Then read the .diff against note.md.
