# Answer key: Northwind practice cases

For self-paced practice with [WALKTHROUGH.md](../../WALKTHROUGH.md). **Open each section only after you've finished the exercise.** Everything here is fictional.

Your answers don't have to match word for word. What matters is whether a reviewer could apply what you wrote, and whether it catches what a bad result could get away with.

---

## 1. Exercise 1: target tasks and exit criteria

**Target Tasks**, rows 5–7:

| Target task | Owner | What good output looks like | How often | Hours today |
|---|---|---|---|---|
| Bug fix from a closed issue | Backend lead | A fix with a regression test that fails before and passes after; no unrelated changes | Several a week | 2 |
| Unit tests for changed code | QA lead | Tests that follow the conventions in tests/conftest.py, cover the failure path, and pass | Every change | 1 |
| Pull request review against the checklist | Staff engineer | Findings by severity with file and line, against docs/review-checklist.md; nothing the linter enforces | Every pull request | 0.75 |

**Exit Criteria**, set before any run:

| Criterion | Northwind's target |
|---|---|
| Target-task pass rate, per task | 80% (each target task must reach it) |
| Share of cases passing every run | 50% |
| Daily active users against assigned seats | 60% by week 4, from 35% in week 1 |
| Pull requests with Claude Code | 25% by week 4, from 9% in week 1 |
| Target tasks ready to expand | 2 of 3 |
| Cost per developer per active day | Under $20 on average (Anthropic's benchmark of about $13 for comparison) |

In the tracker, type just the number in the Target column for rows 5 and 6 (`80%`, `50%`): the formulas compare it with the results. The others can be words.

Check your own: could each of your targets be measured, and is each one a number or a count, not "good"?

---

## 2. Exercise 2: the six cases

The full files are in `~/nw-foundation/eval-set/P-0N/` (or [eval-set/](eval-set/) here): `request.md`, `context.md`, `note.md`, and the reference and weak outputs.

| Case | Target task | Request | Must include | Must not | Weak output | Automatable grader |
|---|---|---|---|---|---|---|
| **P-01** | Bug fix | Fix issue 142: GET /shipments/{id} returns a 500 when the shipment has no carrier yet. A missing carrier is valid for shipments not yet dispatched. | The pull request's tests pass and the full suite passes; carrier_name is null when no carrier is assigned | A change to the response schema; edits outside the shipment lookup; editing an existing test to pass | PR 149 (reverted): dropped carrier_name and edited a test | The merged tests, then reviewer judgment |
| **P-02** | Bug fix | Fix issue 156: searching shipments for a name with an apostrophe, such as O'Brien, returns a 500. | The pull request's tests pass; every value reaches the SQL through `?` placeholders | Quotes escaped by hand in the SQL string | None | The merged tests, then reviewer judgment. **The tests can't tell placeholders from hand-escaping, so the diff decides** |
| **P-03** | Unit tests | Write tests for the carriers sort parameter. | A test per allowed sort value (name, code, on_time) and one for the 400 on an unknown value; conftest fixtures; the suite passes | Network calls; database setup outside conftest | None | The suite passes; a reviewer checks the conventions |
| **P-04** | Unit tests | Add tests for the admin delete endpoint. | A test that a customer gets **403** from the admin delete route, and one that an admin gets 204 | Tests that assert a customer can delete a shipment | PR 161 (closed): asserted a customer gets 204 | The new tests **fail on the bug and pass on the fix** |
| **P-05** | Review | Review pull request 170 against docs/review-checklist.md. Its change is the most recent commit on this branch. | Flags the export route (`app/routes/admin.py`) for missing `require_admin`, with file and line | Comments on formatting or import order (ruff enforces them) | None | Reviewer judgment |
| **P-06** | Review | Review this. | **Asks which pull request (170 or 171) before reviewing** | Picking a pull request without asking | A review of PR 171, posted without asking | Reviewer judgment. Should Claude ask first? **Yes** |

What people most often miss (the P-04 point is the subject of Exercise 3: read it after you've calibrated):

- **P-01:** forgetting *Must not: edit an existing test*. PR 149 "fixed" the 500 by changing a test.
- **P-02:** trusting the tests. A fix that escapes quotes by hand passes them, and it's still the wrong fix.
- **P-04 (read after Exercise 3):** writing Must include as "tests for the endpoint". That lets tests that encode the bug pass (see §3).
- **P-06:** not having a question-first case at all. Knowing when to stop matters as much as doing the work.

---

## 3. Exercise 3: calibration

Use these as **Grader B**. "Both domain experts?" is No: these cases are *Expert and presenter* until a second real expert confirms them. The Grader B column shows the verdicts agreed after any rewrite. The story below the table describes the presenter's first verdict, before the case was rewritten.

| Case | Output | Grader B verdict | Why |
|---|---|---|---|
| P-01 | Weak (PR 149) | **Fail** | Drops carrier_name from the response, and edits a test so it passes |
| P-01 | Reference (PR 151) | **Pass** | One-line fix, regression test, carrier_name null with no carrier |
| P-04 | Weak (PR 161) | **Fail** | Its tests assert that a customer gets 204: they encode the bug |
| P-04 | Reference (PR 163) | **Pass** | 403 for a customer, 204 for an admin, conftest fixtures |
| P-06 | Weak (weak.md) | **Fail** | Reviews PR 171 without asking which pull request was meant |
| P-06 | Reference (reference.md) | **Pass** | Lists both open pull requests and asks which one |

**The disagreement to expect.** If your P-04 case said only "tests for the admin delete endpoint", you probably passed the weak output: its tests *do* test the endpoint, and they pass. In the fictional Northwind session, the QA lead failed it and the presenter passed it, for exactly this reason. The fix is to **rewrite the case**, not to correct a grader: Must include now requires a 403 for a customer. Grade the rewritten case again on a new Calibration row.

Northwind's agreement rate: five of six grades agreed, **83%**, before the rewrite. Once you grade the rewritten P-04 on its new row and the graders agree, the tracker shows six of seven, **86%**. The mock tracker your presenter shows has the first six rows only.

---

## 4. Reading the result

Your own runs will differ: that's the point of measuring. To practise reading a full baseline, here is Northwind's fictional result for all 18 runs (six cases, three runs each). Presenters show the same figures.

| Case | Run 1 | Run 2 | Run 3 | Passed every run? |
|---|---|---|---|---|
| P-01 | Pass | Pass | Pass | Yes |
| P-02 | Pass | **Fail**: tests pass, but quotes escaped by hand | Pass | No |
| P-03 | Pass | Pass | Pass | Yes |
| P-04 | **Fail**: asserted 204 for a customer | Pass | **Fail**: happy path only | No |
| P-05 | Pass | Pass | Pass | Yes |
| P-06 | **Fail**: reviewed PR 171 without asking | Can't tell: asked about the branch, not the pull request | **Fail**: reviewed PR 170 without asking | Needs 3 graded runs |

How to read it:

- **Overall pass rate: 71%** (12 of 17 graded runs; the Can't tell run is left out). That number hides three different stories, so split it by task: the exit criterion is judged per task for that reason.
- **By task:** bug fixes **83%**, unit tests **67%**, pull request reviews **60%**.
- **Consistency: 60%.** Three of the five cases with three graded runs passed every run (P-01, P-03, P-05). They're the first regression set. P-06 needs another run before it counts.
- **P-02 run 2 is the one to dwell on:** the tests passed and the run still failed. Passing tests are necessary, not sufficient.
- **P-04** tested the access rule in one run and not the other two, and nothing in the request said the access rule mattered. That's the clue to the fix.
- **How much to trust it:** two cases and six runs per target task is a first look, not a verdict. One run more or less moves a task's rate by about 17 points. Treat a task that clears its target by a run or two as a candidate, and grow its cases toward the twenty to fifty Anthropic calls a strong start before the expansion is final.

Likely fixes, as noted on the Decisions tab:

| Failure | What it shows | Likely fix |
|---|---|---|
| P-02 run 2 | The repository's CLAUDE.md already says "Use `?` placeholders for every value", and one run in three still escaped by hand. The tests can't catch it | The task can still expand, with review in place. Better still, make the rule checkable (a test or lint rule), because a line in CLAUDE.md alone didn't hold every time |
| P-04 | A team standard Claude doesn't know: test the access rule, not only the happy path | **Build a skill** |
| P-06 | Context the engineer could have given: which pull request | **Improve the brief or CLAUDE.md**: say which pull request, or tell Claude to ask |

**Grading your own runs, case by case:**

| Case | A Pass looks like | Common Fails |
|---|---|---|
| P-01 | Reference tests pass; diff touches only the lookup; carrier_name null | Edits an existing test; drops carrier_name; adds an ownership check (a Fail for scope; note the missing check as a finding) |
| P-02 | Reference tests pass **and** the search uses `?` placeholders | Escaping quotes by hand (tests still pass) |
| P-03 | Tests pass; one per sort value plus the 400; uses `client` and `customer` fixtures | Network calls; own database setup; missing the 400 case |
| P-04 | "Before overlay: fail; after overlay: pass", with a 403 test for a customer | "Before overlay: pass" (misses the bug), or "after overlay: fail" (asserts the bug) |
| P-05 | Flags `app/routes/admin.py` export route for missing `require_admin`, with a line number; the .diff is empty | Many style comments, but the access check missed |
| P-06 | Asks which pull request, 170 or 171, and reviews nothing yet | Reviews either one without asking, however good the review |

"Before overlay" and "after overlay" are how run-case reports a test-writing case: the tests Claude wrote, run first on the code as it was (before the fixed files are copied in), then with the fixed files overlaid.

---

## 5. Exercise 5: decisions

| Target task | Decision | Why | Owner |
|---|---|---|---|
| Bug fix from a closed issue | **Ready to expand** | Passed the criteria; one run escaped quotes by hand instead of using placeholders | Backend lead |
| Unit tests for changed code | **Build a skill** | Tests the happy path, and can assert the bug instead of the access rule | QA lead |
| Pull request review against the checklist | **Improve the brief or CLAUDE.md** | Picks a pull request instead of asking which one | Staff engineer |

Exit criteria, measured against the targets set in Exercise 1:

| Criterion | Target | Measured | Met? |
|---|---|---|---|
| Target-task pass rate, per task | 80% for each task | 1 of 3: bug fixes 83%, unit tests 67%, reviews 60% | No |
| Share of cases passing every run | 50% | 60% | Yes |
| Daily active users against assigned seats | 60% by week 4 | 52% | No |
| Pull requests with Claude Code | 25% by week 4 | 27% | Yes |
| Target tasks ready to expand | 2 of 3 | 1 of 3 | No |
| Cost per developer per active day | Under $20 | $11 | Yes |

**The readout:** the foundation as a whole isn't ready to expand, but one task is. Bug fixes expand. Unit tests go to Workshop 2 with P-03 and P-04 as the skill's baseline. Reviews get a better brief and are measured again. That's a decision a sponsor can act on.
