# Case D-01 context: bug fix from a Jira issue

- Repository: northwind-dispatch-portal
- Pull request: 221 (the merged fix for NWD-212)
- Commit before: nwd-212-base
- Merged ref: pr-221-merged
- Test added: Get_PendingDispatch_HasNoDriverName
- Test files to copy in: api.tests/DispatchesTests.cs
- Suite command: `dotnet test NorthwindDispatch.slnx`
- Case branch: case/D-01
- Type: Capability
- Should Claude ask first? No

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-01
```

## How to grade

Automatable grader: the merged pull request's api.tests/DispatchesTests.cs is copied into each run, then the API
suite runs. "What we noticed" says "Reference tests: pass" or "fail". Then read the run's .diff against note.md:
weak.diff (pull request 219) passes its own new test but fails the merged ones.
