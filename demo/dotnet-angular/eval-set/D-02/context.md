# Case D-02 context: bug fix from a Jira issue (Angular)

- Repository: northwind-dispatch-portal
- Pull request: 231 (the merged fix for NWD-230)
- Commit before: pr-224-merged
- Merged ref: pr-231-merged
- Test added: shows results for the latest query, even when an earlier response arrives last
- Test files to copy in: web/src/app/dispatch-search/dispatch-search.component.spec.ts
- Suite command: `npm --prefix web test`
- Case branch: case/D-02
- Type: Capability
- Should Claude ask first? No

## Run it

Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case's case.json, so the command is the same everywhere:

```
run-case --eval-set ~/nwd-foundation/eval-set --case D-02
```

## How to grade

Automatable grader: the merged pull request's dispatch-search.component.spec.ts is copied into each run, then the
web suite runs. Its tests wait with fakeAsync, so a correct fix that also debounces passes them. The race test makes
the earlier response arrive last: only a fix that drops earlier requests passes it. weak.diff (pull request 229)
passes its own tests and fails the race test.
