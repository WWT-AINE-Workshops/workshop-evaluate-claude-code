# Case D-03 context: unit tests for changed code

- Repository: northwind-dispatch-portal
- Pull request: 224 (the QA lead's tests)
- Commit before: pr-221-merged
- Merged ref: pr-224-merged
- Suite command: `dotnet test NorthwindDispatch.slnx`
- Case branch: case/D-03
- Type: Capability
- Should Claude ask first? No

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-03
```

## How to grade

Automatable grader: the suite runs as Claude left it. The code already works, so the new tests should pass; the
reviewer then checks what they cover and how they are written, against note.md and reference.diff.
