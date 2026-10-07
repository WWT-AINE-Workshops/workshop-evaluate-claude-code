# Answer key: Northwind Dispatch practice cases

For self-paced practice with [WALKTHROUGH-dotnet.md](../../WALKTHROUGH-dotnet.md). **Open each section only after you've finished the exercise.** Everything here is fictional.

Your answers don't have to match word for word. What matters is whether a reviewer could apply what you wrote, and whether it catches what a bad result could get away with.

---

## 1. Exercise 1: target tasks and exit criteria

**Target Tasks**, rows 5–7:

| Target task | Owner | What good output looks like | How often | Hours today |
|---|---|---|---|---|
| Bug fix from a Jira issue | Backend lead | A fix in the right layer with a regression test that fails before and passes after; the API contract unchanged; no unrelated changes | Several a week | 2 |
| Unit tests for changed code | QA lead | xUnit tests through `DispatchApiFactory` and `ClientAs`, or Jest tests with a stubbed `DispatchService`; they cover the failure path and the access rule, and pass | Every change | 1 |
| Pull request review against the checklist | Staff engineer | Findings by severity with file and line, against docs/review-checklist.md; nothing the compiler or linter already reports | Every pull request | 0.75 |

**Exit Criteria**, set before any run:

| Criterion | Northwind Dispatch's target |
|---|---|
| Target-task pass rate, per task | 80% for each target task |
| Share of cases passing every run | 50% |
| Daily active users against assigned seats | 85% by week 4, from 75% in week 1 |
| Pull requests with Claude Code | 60% by week 4, from 48% in week 1 |
| Target tasks ready to expand | 2 of 3 |
| Cost per developer per active day | Under $25 on average (Anthropic's benchmark of about $13 for comparison) |

A team that has used Claude Code for a long time starts with high adoption, so adoption targets say little here. The quality criteria carry the decision.

---

## 2. Exercise 2: the six cases

The full files are in `~/nwd-foundation/eval-set/D-0N/` (or [eval-set/](eval-set/) here): `request.md`, `context.md`, `note.md`, `case.json`, and the reference and weak outputs.

| Case | Target task | Request | Must include | Must not | Weak output | Automatable grader |
|---|---|---|---|---|---|---|
| **D-01** | Bug fix | Fix NWD-212: GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet. | The merged tests pass; a pending dispatch returns 200 with `driverName` null | A 404 or an empty string for a dispatch that exists; catching the exception; editing an existing test | PR 219 (reverted): returned 404 and added a test asserting it | The merged tests, then reviewer judgment |
| **D-02** | Bug fix | Fix NWD-230: the dispatch search box sometimes shows results for an earlier query. | The earlier request is dropped when a newer query arrives (`switchMap` or equivalent); the merged spec passes | `debounceTime` alone; changed assertions in existing tests | PR 229 (closed): debounced only, with green tests | The merged spec, whose race test makes the earlier response arrive last. **The weak fix's own tests pass: only the race test catches it** |
| **D-03** | Unit tests | Write tests for GET /api/dispatches: the status filter and the sort parameter, including the 400 for an unknown sort. | A test per sort value, the eta order with no-eta last, the status filter, the 400 naming the allowed values; `IClassFixture<DispatchApiFactory>` and `ClientAs`; the suite passes | A hand-built `HttpClient` or a second factory; any controller change | None | The suite passes; a reviewer checks the conventions |
| **D-04** | Unit tests | Add tests for POST /api/dispatches/{id}/cancel. | A test that a customer gets **403** and the dispatch is unchanged; a dispatcher gets 204 | Tests that assert a customer can cancel | PR 242 (closed): asserted a customer gets 204 | The new tests **fail on the bug and pass with the fixed controller** |
| **D-05** | Review | Review pull request 250 against docs/review-checklist.md. Its change is the most recent commit on this branch. | Flags `GET /api/dispatches/export` for having no policy (customers download every customer's contact details), with file and line | Flagging `Csv.Field`'s leading apostrophe as a bug; style comments only | None | Reviewer judgment |
| **D-06** | Review | Review this. | **Asks which pull request (250 or 251) before reviewing** | Picking a pull request without asking | A review of PR 251, posted without asking | Reviewer judgment. Should Claude ask first? **Yes** |

What people most often miss (the D-02 and D-04 points are the subject of Exercise 3: read them after you've calibrated):

- **D-01:** forgetting *Must not: a 404 for a dispatch that exists*. PR 219 made the 500 go away and was still wrong.
- **D-02 (read after Exercise 3):** trusting green CI. The weak fix updated its tests and they pass. Only a test that makes the earlier response arrive last shows the race.
- **D-04 (read after Exercise 3):** writing Must include as "tests for the cancel endpoint". That lets tests that encode the bug pass (see §3).
- **D-05:** not saying what must *not* be flagged. A reviewer who calls the formula-injection guard a bug is wrong, and the case should say so.
- **D-06:** not having a question-first case at all. Knowing when to stop matters as much as doing the work.

---

## 3. Exercise 3: calibration

Use these as **Grader B**. "Both domain experts?" is No: these cases are *Expert and presenter* until a second real expert confirms them. The Grader B column shows the verdicts agreed after any rewrite. The story below the table describes the presenter's first verdict, before the case was rewritten.

| Case | Output | Grader B verdict | Why |
|---|---|---|---|
| D-01 | Weak (PR 219) | **Fail** | Returns 404 for a dispatch that exists, by catching the exception, and adds a test that asserts it |
| D-01 | Reference (PR 221) | **Pass** | One-character fix (`?.`), regression test, `driverName` null with no driver |
| D-02 | Weak (PR 229) | **Fail** | Debounces but keeps `mergeMap`: a slow earlier response still replaces the newer results |
| D-02 | Reference (PR 231) | **Pass** | `switchMap` drops the earlier request; the race test proves it; existing assertions unchanged |
| D-04 | Weak (PR 242) | **Fail** | Its tests assert that a customer gets 204: they encode the bug |
| D-04 | Reference (PR 244) | **Pass** | 403 for a customer with the dispatch unchanged, 204 for a dispatcher, the fixture conventions |
| D-06 | Weak (weak.md) | **Fail** | Reviews PR 251 without asking which pull request was meant |
| D-06 | Reference (reference.md) | **Pass** | Lists both open pull requests and asks which one |

**The disagreements to expect.** If your D-02 case said only "fix the stale results", you may have passed the weak output: the debounce makes the bug rare, its tests are green, and the diff looks like a fix. In the fictional session the frontend lead failed it and the presenter passed it. The same happens on D-04 when the case says only "tests for the cancel endpoint". The fix is to **rewrite the case**, not to correct a grader: Must include now names the earlier request being dropped (D-02) and the customer's 403 (D-04). Grade the rewritten cases again on new Calibration rows.

Northwind Dispatch's agreement rate: six of eight grades agreed, **75%**.

---

## 4. Reading the result

Your own runs will differ: that's the point of measuring. To practise reading a full baseline, here is the fictional result for all 18 runs (six cases, three runs each), with each engineer's personal setup left out. Presenters show the same figures.

| Case | Run 1 | Run 2 | Run 3 | Passed every run? |
|---|---|---|---|---|
| D-01 | Pass | Pass | Pass | Yes |
| D-02 | **Fail**: debounced, kept `mergeMap` | Pass | Pass | No |
| D-03 | Pass | **Fail**: built its own `WebApplicationFactory` | Pass | No |
| D-04 | **Fail**: dispatcher paths only, passed on the bug | Pass | **Fail**: asserted 204 for a customer | No |
| D-05 | Pass | Pass | Pass | Yes |
| D-06 | **Fail**: reviewed PR 250 without asking | Pass | **Fail**: reviewed PR 251 without asking | No |

How to read it:

- **Overall pass rate: 67%** (12 of 18 runs). That number hides three different stories, so split it by task: the exit criterion is judged per task for that reason.
- **By task:** bug fixes **83%**, unit tests **50%**, pull request reviews **67%**.
- **Consistency: 33%.** Two of the six cases passed every run (D-01, D-05). They're the first regression set.
- **D-02 run 1 is the one to dwell on:** its own tests passed, CI would have been green, and the run still failed. Passing tests are necessary, not sufficient.
- **D-05 passed every run, and D-06 failed two of three.** Claude Code reviews well when it knows *what* to review. The gap is in the brief, not the review.
- **These runs leave personal setup out.** Many of this team's engineers have their own CLAUDE.md and skills, so their everyday results may be better or worse. To measure the team's shared setup, commit it to the repository and run the cases again.
- **How much to trust it:** two cases and six runs per target task is a first look, not a verdict. One run more or less moves a task's rate by about 17 points. Treat a task that clears its target by a run or two as a candidate, and grow its cases toward the twenty to fifty Anthropic calls a strong start before the expansion is final.

Likely fixes, as noted on the Decisions tab:

| Failure | What it shows | Likely fix |
|---|---|---|
| D-02 run 1 | The review checklist says to cancel the previous request (`switchMap`), but CLAUDE.md doesn't, and the run never read the checklist | **Improve the brief or CLAUDE.md**: add the RxJS rule, and a race test as the team's pattern for typeahead fixes. The task itself still clears its target |
| D-03 run 2, D-04 | Team standards Claude doesn't know: use the fixture, and test the access rule, not only the happy path | **Build a skill** |
| D-06 | Context the engineer could have given: which pull request | **Improve the brief or CLAUDE.md**: say which pull request, or tell Claude to ask |

**Grading your own runs, case by case:**

| Case | A Pass looks like | Common Fails |
|---|---|---|
| D-01 | Reference tests pass; diff touches only the lookup; `driverName` null | Returns 404; catches `NullReferenceException`; edits an existing test |
| D-02 | Reference spec passes **and** the component drops the earlier request | `debounceTime` alone (its own tests can still pass); changed assertions |
| D-03 | Tests pass; one per sort value plus the 400; uses the fixture and `ClientAs` | A hand-built client or a second factory; missing the eta order or the 400 |
| D-04 | "Before overlay: fail; after overlay: pass", with a 403 test for a customer | "Before overlay: pass" (misses the bug), or "after overlay: fail" (asserts the bug) |
| D-05 | Flags the export route in `api/Controllers/DispatchesController.cs` for having no policy, with a line number; the .diff is empty | Flags `Csv.Field`'s apostrophe as a bug; style comments, with the access check missed. In testing, real runs often named the file but not the line: decide in calibration whether your case requires the line, and say so in Must include |
| D-06 | Asks which pull request, 250 or 251, and reviews nothing yet | Reviews either one without asking, however good the review |

"Before overlay" and "after overlay" are how run-case reports a test-writing case: the tests Claude wrote, run first on the code as it was (before the fixed files are copied in), then with the fixed files overlaid.

---

## 5. Exercise 5: decisions

| Target task | Decision | Why | Owner |
|---|---|---|---|
| Bug fix from a Jira issue | **Ready to expand** | Reached its 80% target (83%); one run debounced instead of cancelling the earlier request, so the RxJS rule goes into CLAUDE.md as a follow-up | Backend lead |
| Unit tests for changed code | **Build a skill** | Skips the team's fixture, and can test the happy path or assert the bug instead of the access rule | QA lead |
| Pull request review against the checklist | **Improve the brief or CLAUDE.md** | Reviews accurately, but picks a pull request instead of asking which one | Staff engineer |

Exit criteria, measured against the targets set in Exercise 1:

| Criterion | Target | Measured | Met? |
|---|---|---|---|
| Target-task pass rate, per task | 80% for each task | 1 of 3: bug fixes 83%, unit tests 50%, reviews 67% | No |
| Share of cases passing every run | 50% | 33% | No |
| Daily active users against assigned seats | 85% by week 4 | 83% | No |
| Pull requests with Claude Code | 60% by week 4 | 58% | No |
| Target tasks ready to expand | 2 of 3 | 1 of 3 | No |
| Cost per developer per active day | Under $25 | $16 | Yes |

**The readout:** high adoption hasn't yet turned into consistent quality, task by task. Bug fixes expand, with one rule added to CLAUDE.md. Unit tests go to Workshop 2 with D-03 and D-04 as the skill's baseline. Reviews get a better brief and are measured again. The cases that passed every run, D-01 and D-05, become the regression set for every later change to CLAUDE.md, a skill, the model, or the Claude Code version.
