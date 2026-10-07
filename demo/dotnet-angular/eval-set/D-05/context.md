# Case D-05 context: pull request review

- Repository: northwind-dispatch-portal
- Pull request: 250 (open: export dispatches as CSV)
- Case branch: case/D-05 (the pull request's head)
- Type: Capability
- Should Claude ask first? No

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-05
```

## How to grade

Review case: nothing runs a test. Read the reply (.md) against note.md and reference.md. The .diff should be empty.
