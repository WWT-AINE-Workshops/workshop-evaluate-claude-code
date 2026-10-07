# Case D-04 context: unit tests that must catch a bug

- Repository: northwind-dispatch-portal
- Pull request: 244 (cancel requires a dispatcher, with its tests)
- Commit before: pr-231-merged
- Merged ref: pr-244-merged
- Fixed code to overlay: api/Controllers/DispatchesController.cs
- Suite command: `dotnet test NorthwindDispatch.slnx`
- Case branch: case/D-04
- Type: Capability
- Should Claude ask first? No

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-04
```

## How to grade

Automatable grader (check-before): the API suite runs twice. First on today's code as Claude left it: good tests
fail here, because a customer can cancel. Then with the fixed controller from pull request 244 copied in: good tests
pass. weak.diff (pull request 242) does the opposite.
