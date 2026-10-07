# demo/dotnet-angular/: the Northwind Dispatch practice kit

Everything here is **fictional**: Northwind Freight, its people, its pull requests, and its results don't exist. The kit lets you work through the whole workshop on a small ASP.NET Core and Angular codebase before, or instead of, using your own.

**Follow [WALKTHROUGH-dotnet.md](../../WALKTHROUGH-dotnet.md).** This page only says what each item is. [demo/README.md](../README.md) lists the other practice variants.

| Item | What it is |
|---|---|
| `northwind-dispatch.bundle` | The practice repository's full history in one file. You clone it, on any OS, in the walkthrough's setup |
| `northwind-dispatch-portal/` | The fictional service (ASP.NET Core 10 with xUnit, Angular 19 with Jest) that the history starts from. **Don't run cases here, and don't edit it** |
| `make-dispatch-history.sh` | Builds the bundle and the case files from `northwind-dispatch-portal/`. Kit maintainers run it; participants clone the bundle instead |
| `eval-set/D-01` … `D-06/` | A read-only copy of the six practice cases, for browsing on GitHub. This is the answer key for Exercise 2, so look after you've written your own cases |
| `ANSWERS.md` | The answer key for Exercises 1–5. Open each section only after the exercise |

## The six practice cases

| Case | Target task | Pull request | What makes it interesting |
|---|---|---|---|
| D-01 | Bug fix from a Jira issue | #221 | The weak attempt (#219) made the 500 a 404, for a dispatch that exists, and tested it |
| D-02 | Bug fix from a Jira issue (Angular) | #231 | The weak attempt (#229) debounced the search, and its tests were green. Only a race test shows it's still wrong |
| D-03 | Unit tests for changed code | #224 | Tests for working code: the reviewer checks the fixture conventions |
| D-04 | Unit tests for changed code | #244 | Good tests fail on the bug. The weak attempt (#242) asserted it |
| D-05 | Pull request review | #250 (open) | One real finding to catch, and one safe line that looks suspicious |
| D-06 | Pull request review | #250 and #251 (open) | "Review this": the right answer is a question |

## Two warnings

- **The service contains deliberate weaknesses.** The cases depend on them, and the practice history fixes only some of them, in later pull requests. Never deploy it, and don't fix the copy in this folder.
- **`~/nwd-foundation` holds the answers.** It has the full history and the reference outputs. Each run happens in its own container that sees only that run's clone, never `~/nwd-foundation`. The walkthrough explains why.
