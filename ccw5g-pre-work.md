# Evaluate Claude Code on Your Own Work

**Claude Lab** · Before the workshop

*Turn your merged pull requests into evidence, run a baseline, and decide what to expand*

Claude Code Adoption Bootcamps · Workforce AI Practice · Level: Intermediate · Current as of 2 October 2026

|  |  |
| --- | --- |
| Time needed | About 65 minutes in total, shared across the attending team, plus about 10 minutes per attendee for Step 6. Most of it goes on choosing merged pull requests. |
| Workshop length | 3 hours, virtual |
| Level | Intermediate |
| Prerequisites | No earlier workshop and no skills required. Merged pull requests for each target task, the repositories they were merged into, and at least one senior engineer or reviewer for the full session. |
| Who completes it | One coordinator for the whole team, usually the foundation owner, with help from each target task's owner for Steps 2 and 3, and from a Claude administrator (an Admin or Owner) for Step 4. Every attendee completes Step 6 for themselves: the coordinator shares the workshop repository with each attendee, which holds Step 6's instructions and the templates. |

In this workshop your team turns work it has already merged into an evaluation set: a fixed list of engineering requests, each with a merged pull request as the standard, that you run against Claude Code to measure what it can take on today. That is the evidence for your expansion decision. The workshop cannot find your pull requests for you. This sheet is about collecting them, and the people who can judge them, so the three hours go on building and measuring rather than searching.

## What you will bring to the workshop

- The foundation evaluation tracker, with the Target Tasks tab filled in
- An eval-set folder holding two or three merged pull requests per target task, one subfolder each, with secrets removed
- A case branch at the commit before each pull request, pushed where every attendee can clone it
- Usage figures for the engineers building the foundation, if a Claude administrator can see them
- The decision the foundation supports, and who makes it
- The names of the domain experts attending, and the target tasks each can judge
- Every attendee able to clone the repositories in scope, run their tests, and run claude -p

## Before you start

- The tracker spreadsheet that came with this sheet: foundation-evaluation-tracker.xlsx
- Access to the repositories in scope, including their pull request history
- A computer running macOS, Linux, or Windows with WSL, with a terminal, git 2.28 or later, Python 3.11 to 3.13, and Claude Code 2.1.257 or later signed in, on a seat that includes Claude Code. If you are missing any of them, Step 6 and the workshop repository tell you how to install them. You do not need to have used a terminal before
- Budget for about six claude -p runs per attendee in the session, plus repeats afterwards
- The workshop repository, which holds the templates folder (the tracker, eval-run-settings.json, run-case.sh, check-setup.sh, and start.sh) and WALKTHROUGH.md, the step-by-step guide
- Fifteen minutes with each target task's owner, or their notes, for Steps 2 and 3

## The steps at a glance

| Step | What you do | Time |
| --- | --- | --- |
| 1 | Set up an eval-set folder | About 5 minutes |
| 2 | Fill in the Target Tasks tab | About 15 minutes |
| 3 | Collect merged pull requests | About 30 minutes |
| 4 | Note usage so far | About 10 minutes |
| 5 | Name the decision and the experts | About 5 minutes |
| 6 | Check your access | About 10 minutes per attendee, up to an hour if tools need installing |

## Step 1: Set up an eval-set folder · About 5 minutes

**Why it matters.** Every case built in the workshop points to files: the request, the merged pull request that sets the standard, and any weak earlier change. Keeping them outside every repository, and running Claude in a separate folder, stops Claude Code from finding the merged answer during a run and turning a test into an open-book exam.

### How to do it

1. Create a folder called eval-set somewhere outside every git repository, for example in your home folder. On Windows, keep it inside WSL (your Ubuntu home folder), not on the Windows side or a network share, which the scripts handle badly. Each attendee who runs cases keeps their own copy, for their outputs.
2. Save foundation-evaluation-tracker.xlsx and eval-run-settings.json in it, and create an empty outputs subfolder for the replies and diffs that runs produce.
3. Inside eval-set, create one empty subfolder per pull request as you choose them in Step 3, named P-01, P-02, and so on.
4. In the workshop, runs happen in a different folder, such as nw-runs in your home folder. Keep it apart from eval-set: never put one inside the other.

### Example

```
eval-set/foundation-evaluation-tracker.xlsx
eval-set/eval-run-settings.json
eval-set/outputs/
eval-set/P-01/   request.md   context.md   reference.diff   weak.diff   note.md
eval-set/P-02/   ...
```

**Done when.** The folder exists outside every repository, with the tracker, eval-run-settings.json, and an outputs subfolder inside it.

**If you get stuck.** If your organization does not allow a shared folder, keep it on the coordinator's machine. The coordinator shares their screen in the workshop.

## Step 2: Fill in the Target Tasks tab · About 15 minutes

**Why it matters.** The foundation is judged task by task: the Summary tab gives a pass rate per target task, and the workshop ends with a decision for each. Choosing them before anyone sees a result keeps the evaluation honest.

### How to do it

1. List the three to five engineering tasks Claude Code is meant to take on first: work done often, judged by a test or a reviewer, with merged pull requests that show what good looks like. Typical examples: bug fixes from closed issues, unit tests for changed code, pull request review, and docs updates.
2. Ask each task's owner for the values in the table below, and add one row per task.
3. Leave Decision set to Not decided yet, and leave every other tab, including Exit Criteria, for the session. They are completed together in the workshop.
4. Use exactly the same task name everywhere afterwards. The Summary tab matches cases to tasks by name.

### What goes in each column

| Column | What to write | Example |
| --- | --- | --- |
| Target task | A short name for the kind of work | Unit tests for changed code |
| Owner (role) and Team | The role that would approve this work in review, and the team that does it most | QA lead; Platform |
| What good output looks like | One or two lines a reviewer would agree with | Tests that follow the conventions in tests/conftest.py, cover the failure path, and pass |
| How often it happens | In plain words | Every change |
| Hours per instance today | A rough number, for an engineer working without Claude Code | 1 |
| Inputs it needs | What an engineer needs on hand to do it | The diff and the existing tests |

*Row 4 of the tab holds a filled-in example. Start your entries on row 5.*

**Done when.** Three to five target tasks have a row each, with an owner and a line on what good output looks like.

**If you get stuck.** If the tasks are not chosen yet, list the work early users rely on Claude Code for most, for the foundation owner to confirm.

## Step 3: Collect merged pull requests · About 30 minutes

**Why it matters.** The merged pull request proves a case can be passed and sets the standard Claude Code is judged against. Its tests become the first grader: a good fix makes them pass without breaking the rest of the suite.

### How to do it

1. For each target task, pick two or three recent pull requests the team merged and was happy with, preferably ones that came from an issue and added or changed a test.
2. In a clone, git rev-parse `<merged commit>`^ gives the commit before the pull request, where the merged commit is the merge or squash commit your Git host shows. If it was rebased in as several commits, use the parent of the first.
3. Create a case branch at that commit and push it, so every attendee can clone it: git branch case/P-01 `<commit before>`, then git push origin case/P-01. In the workshop, each clone stops at this branch, so the merged fix is not in its history.
4. Create a subfolder P-01, P-02, and so on for each, and save the files in the table below. git diff --output=reference.diff `<commit before>` `<merged commit>` saves the change (use --output rather than >: in Windows PowerShell, > changes the file's encoding); git diff --stat lists the files it touched.
5. Save any earlier Claude Code change for the same work that was reverted, reworked, or rejected as weak.diff, or as weak.md for a review or other prose. For a review case, save the review the team acted on as reference.md. Note any vague request that went wrong, such as "Review this" with two pull requests open: it becomes a case where Claude should ask first.
6. Remove secrets and confidential data from every file, replacing each with a placeholder such as `<API_KEY>`. Confirm with the repository owner that the repository holds no live secrets at the commit before; if it does, choose another pull request.

### The files for one pull request

| File | What it holds | Example from a fictional team |
| --- | --- | --- |
| request.md | The request as an engineer would ask for it, often the issue text | Fix issue 142: GET /shipments/{id} returns a 500 when the shipment has no carrier yet. |
| context.md | Repository, pull request number, the commit before, the merged commit, the tests it added, and the command that runs the suite | northwind-shipments-api; pull request 151; commit before: issue-142-base; case branch: case/P-01; test added: test_get_shipment_without_carrier, in tests/test_shipments.py; suite: pytest -q |
| reference.diff | The merged change, saved with git diff | One line in app/routes/shipments.py, a regression test, and a changelog entry |
| weak.diff | A reverted, reworked, or rejected Claude Code change for the same work. Leave it out if none exists | Pull request 149, reverted because it dropped carrier_name from the response and edited a test to pass |
| note.md | One or two lines: who approved the pull request, and what a reviewer checks that the tests do not | Backend lead approved. carrier_name must stay in the response, as null. |

**Done when.** Two or three subfolders per target task, each with request.md, context.md, reference.diff, and note.md; a case branch pushed for each; and no secrets in any file.

**If you get stuck.** If a task has only one suitable pull request, bring it. A pull request without tests still counts: the reviewer's judgment becomes its grader. A task with no merged work worth copying may not be a good target; raise it in the workshop. If you cannot push branches to the shared repository, write the commit before in context.md; attendees create the branch in their own clone in the workshop.

## Step 4: Note usage so far · About 10 minutes

**Why it matters.** In Exercise 1 the team sets adoption and cost targets on the Exit Criteria tab from the foundation's own week-1 figures, with Anthropic's published figures beside them for comparison only. Without a starting point, a target is a guess.

### How to do it

1. Ask a Claude administrator, an Admin or Owner, to open the Claude Code analytics dashboard at claude.ai/analytics/claude-code, on Team and Enterprise plans. API customers use the Claude Console at platform.claude.com/claude-code.
2. From the Adoption chart, or the Activity chart in the Console, note daily active users in the foundation's first week and in the most recent week, and the number of seats assigned to it.
3. If contribution metrics are turned on, note PRs with Claude Code (%) for the same two weeks. They need a GitHub admin to install the Claude GitHub app, and a Claude Owner to turn on Claude Code analytics.
4. From the spend report, exported from the organization's analytics settings, note the estimated spend for the engineers building the foundation since it began. Divide it by the sum of daily active users over the same days to get a cost per developer per active day.

### Example

> 20 seats; 7 daily active users in week 1 (35 percent), 9 in week 2 (45 percent). PRs with Claude Code: 9 percent. $1,100 over 100 developer active days: about $11 each.

**Done when.** The figures are written in the box below, or the box says Not available.

**If you get stuck.** If nobody with access can share them, write Not available. The targets are then set in the room from what the customer representative knows. The quality evidence, the main work of the day, does not depend on them.

## Step 5: Name the decision and the experts · About 5 minutes

**Why it matters.** The foundation supports one decision, and every case needs a verdict a domain expert would stand behind. The workshop's standard is that two experts, working separately, agree, so who attends decides which cases reach it in the room.

### How to do it

1. Write the decision the foundation supports, and who makes it, in one sentence.
2. List the people attending who would approve or reject a pull request for each target task in a real review, with the tasks each can judge. Check that every task has at least one.

### Example

```
Decision: whether to offer Claude Code to every backend team, made by the head of engineering.
Backend lead: bug fix from a closed issue. QA lead: unit tests for changed code. Staff engineer: pull request review against the checklist.
```

**Done when.** The decision, and at least one expert for every target task, are written in the box below.

**If you get stuck.** One expert is enough to start. The presenter grades second, and the case is marked Expert and presenter until a second expert confirms it. If nobody can name the decision, write the most likely one; the workshop opens by agreeing it.

## Step 6: Check your access · About 10 minutes per attendee, up to an hour if tools need installing

**Why it matters.** In the workshop each attendee replays cases and grades each run with the pull request's tests. A sign-in problem or a test suite that will not run costs the whole group its time.

### How to do it

1. Get the workshop repository, as section 1.5 of its WALKTHROUGH.md describes, and run: bash ~/ccw5g/templates/check-setup.sh. It checks git, Python, and Claude Code, changes nothing, and prints how to fix anything missing. Section 1 of the walkthrough explains each install step by step, for macOS, Linux, and Windows, and assumes no experience with terminals.
2. Fix every line the check marks FIX, open a new terminal window, and run the check again until it says All set. Then run bash ~/ccw5g/templates/check-setup.sh --live, which makes one tiny real call to Claude Code (a few cents) to prove you are signed in.
3. Clone each repository you will work on, or confirm that you can.
4. In one clone, run git checkout --detach `<commit before>` for one of the collected pull requests, install the repository's dependencies the way its README says, and run its test suite with the command written in context.md. For a Python service, that is often: python3 -m venv .venv, then source .venv/bin/activate, then pip install -r requirements.txt. Detaching leaves your branches untouched.
5. Note the exact test command. In the workshop it goes into --allowedTools, so Claude can run the tests without a permission prompt.

**Done when.** The check says All set, including the live check, and each attendee has run one in-scope repository's test suite at the commit before a pull request.

**If you get stuck.** If Claude Code will not start or sign in, ask your Claude administrator for a seat that includes Claude Code. If a company laptop will not allow WSL or installs, ask your IT team, or use another computer. If the tests will not run on your machine, pair with a colleague whose machine runs them, and grade in their group. If the suite needs a database, other services, or secrets, choose a pull request whose tests run without them, or bring the local setup steps your CI uses. In a monorepo, note the command that runs only the affected package's tests.

## Where to put it

**Usage so far: seats, daily active users, PRs with Claude Code, and cost per developer per active day**

>

**The decision the foundation supports and who makes it; the domain experts attending and the target tasks each can judge**

>

## Terms used in this sheet

| Term | What it means here |
| --- | --- |
| Foundation | The first group of engineers and target tasks an organization uses to prove Claude Code before rolling it out more widely. Anthropic calls it a pilot group. |
| Target task | A kind of engineering work Claude Code is meant to take on first, such as bug fixes. |
| Reference output | The merged pull request: the standard Claude Code is judged against. |
| Commit before | The commit the pull request started from. Each case is replayed from it. |
| Case branch | A branch at the commit before, so a clone in the workshop can stop there. |
| Eval case | One request with its standard: what a good result must include, what it must not do, and the merged pull request as the reference. |
| Domain expert | Someone who would approve or reject this work in a real review. |
| Exit criteria | The success criteria the expansion decision is checked against, each with a target set before any result. |

## Questions people ask

**Do we need to write evaluation cases before the workshop?**

No. Collect the pull requests; the cases are written together in the session, where the presenter can help with the standard.

**Our code is confidential. Does any of it go to WWT?**

No. The folder and the repositories stay with your team, and nothing is sent to WWT. Your group shares a screen during the exercises, so remove anything that should not be seen on a call.

**What will the runs cost?**

Each run is a real model call on your plan or API account. Expect about six runs per attendee in the session: in testing, a practice run cost about $0.40, so about $2.50 per attendee. Each run's output reports its cost, and the tracker records it. Anthropic's benchmark from enterprise deployments is about $13 per developer per active day.

**Can we use Claude Code to find the pull requests?**

Yes, for searching, such as listing merged pull requests that closed an issue and added a test. The task owner, not Claude Code, decides which ones meet the standard.

## Sharing what you prepared

Nothing needs to be sent to WWT. Share the workshop repository with every attendee: Step 6 and the templates are in it. Bring the tracker and the eval-set folder to the workshop on the coordinator's machine, ready to share on screen.

## Checklist

- [ ] eval-set folder created outside every repository, with the tracker, eval-run-settings.json, and an outputs subfolder inside
- [ ] Target Tasks tab complete: three to five tasks, each with an owner
- [ ] Two or three merged pull requests per task, each with request.md, context.md, reference.diff, and note.md
- [ ] Any reverted, reworked, or rejected earlier changes saved as weak.diff or weak.md
- [ ] A case branch at the commit before each pull request, pushed where attendees can clone it
- [ ] Secrets and confidential information removed, and no live secrets at the commits used
- [ ] Usage figures written down, or marked Not available
- [ ] The decision and the domain experts named, with the tasks each can judge
- [ ] Every attendee has Claude Code 2.1.257 or later, has run claude -p, and has run one repository's test suite

Questions? Contact your WWT presenter.

---

*Make a new world happen.*

*This file is generated from the same source as the Word version. Send corrections to your WWT presenter rather than editing it.*
