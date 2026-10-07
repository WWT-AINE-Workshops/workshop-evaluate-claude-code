# Case D-06 context: pull request review (ambiguous request)

- Repository: northwind-dispatch-portal
- Open pull requests: 250 (branch pr-250) and 251 (branch pr-251)
- Case branch: case/D-06 (main), with pr-250 and pr-251 copied in
- Type: Capability
- Should Claude ask first? Yes

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-06
```

## How to grade

Review case: nothing runs a test. Read the reply (.md): does it ask which pull request to review before reviewing?
