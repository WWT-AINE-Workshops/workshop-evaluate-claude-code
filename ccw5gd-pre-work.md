# Evaluate Claude Code on Your Own Work

**Claude Lab** · Before the workshop

*Turn your merged pull requests into evidence, run a baseline, and decide what to expand*

Claude Code Adoption Bootcamps · Workforce AI Practice · Level: Intermediate · Current as of 2 October 2026

|  |  |
| --- | --- |
| Time needed | About 65 minutes in total, shared across the attending team, plus about 10 minutes per attendee for Step 6. Most of it goes on choosing merged pull requests. |
| Workshop length | 3 hours, virtual |
| Level | Intermediate |
| Prerequisites | No earlier workshop and no skills required. Merged pull requests for each target task in .NET or Angular repositories, and at least one senior engineer or reviewer for the full session. |
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
- A computer running Windows, macOS, or Linux (WSL works too), with git 2.28 or later, the .NET 10 SDK, Docker running Linux containers with 6 GB of memory, about 8 GB of free disk, and Claude Code 2.1.257 or later signed in, on a seat that includes Claude Code. Step 6 and the workshop repository tell you how to check them
- Budget for about six claude -p runs per attendee in the session, plus repeats afterwards
- The workshop repository, which holds the templates folder (the tracker, eval-run-settings.json, run-case.cs, check-setup.cs, and the run image's Dockerfile) and WALKTHROUGH-dotnet.md, the step-by-step guide
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

1. Create a folder called eval-set somewhere outside every git repository, for example in your home folder. Each attendee who runs cases keeps their own copy, for their outputs.
2. Save foundation-evaluation-tracker.xlsx and eval-run-settings.json in it, and create an empty outputs subfolder for the replies and diffs that runs produce.
3. Inside eval-set, create one empty subfolder per pull request as you choose them in Step 3, named B-01, B-02, and so on. Add eval-run.json, which names the model every run uses: {"model": "`<the model your engineers use day to day>`", "runs": 3}.
4. In the workshop, runs happen in a different folder, such as eval-runs in your home folder. Keep it apart from eval-set: never put one inside the other.

### Example

```
eval-set/foundation-evaluation-tracker.xlsx
eval-set/eval-run-settings.json
eval-set/eval-run.json
eval-set/outputs/
eval-set/B-01/   request.md   case.json   context.md   reference.diff   weak.diff   note.md
eval-set/B-02/   ...
```

**Done when.** The folder exists outside every repository, with the tracker, eval-run-settings.json, and an outputs subfolder inside it.

**If you get stuck.** If your organization does not allow a shared folder, keep it on the coordinator's machine. The coordinator shares their screen in the workshop.

## Step 2: Fill in the Target Tasks tab · About 15 minutes

**Why it matters.** The foundation is judged task by task: the Summary tab gives a pass rate per target task, and the workshop ends with a decision for each. Choosing them before anyone sees a result keeps the evaluation honest.

### How to do it

1. List the three to five engineering tasks Claude Code is meant to take on first: work done often, judged by a test or a reviewer, with merged pull requests that show what good looks like. Typical examples: bug fixes from Jira issues, unit tests for changed code, pull request review, and docs updates.
2. Ask each task's owner for the values in the table below, and add one row per task.
3. Leave Decision set to Not decided yet, and leave every other tab, including Exit Criteria, for the session. They are completed together in the workshop.
4. Use exactly the same task name everywhere afterwards. The Summary tab matches cases to tasks by name.

### What goes in each column

| Column | What to write | Example |
| --- | --- | --- |
| Target task | A short name for the kind of work | Unit tests for changed code |
| Owner (role) and Team | The role that would approve this work in review, and the team that does it most | QA lead; Platform |
| What good output looks like | One or two lines a reviewer would agree with | xUnit tests through the team's WebApplicationFactory fixture, or Jest tests with a stubbed service, that cover the failure path and the access rule, and pass |
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
3. Keep a full-history clone of the repository in a repos folder beside eval-set, and create the case branch in it, at that commit: git -C repos/`<repository>` branch case/B-01 `<commit before>`. Nothing is pushed, so no Bitbucket Pipelines build starts. Share the repos and eval-set folders with your team the same way. In the workshop, each run's clone stops at this branch, so the merged fix is not in its history. For an open pull request a review case needs, make a local branch from it too: git -C repos/`<repository>` branch pr-`<N>` origin/`<its branch>`.
4. Create a subfolder B-01, B-02, and so on for each, and save the files in the table below. case.json holds the case's setup and test commands for run-case; section 10 of WALKTHROUGH-dotnet.md has an example. git diff --output=reference.diff `<commit before>` `<merged commit>` saves the change (use --output rather than >: in Windows PowerShell 5.1, > writes the file as UTF-16); git diff --stat lists the files it touched.
5. Save any earlier Claude Code change for the same work that was reverted, reworked, or rejected as weak.diff, or as weak.md for a review or other prose. For a review case, save the review the team acted on as reference.md. Note any vague request that went wrong, such as "Review this" with two pull requests open: it becomes a case where Claude should ask first.
6. Remove secrets and confidential data from every file, replacing each with a placeholder such as `<API_KEY>`. Confirm with the repository owner that the repository holds no live secrets at the commit before; if it does, choose another pull request.

### The files for one pull request

| File | What it holds | Example from a fictional team |
| --- | --- | --- |
| request.md | The request as an engineer would ask for it, often the issue text | Fix NWD-212: GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet. |
| context.md | Repository, pull request number, the commit before, the merged commit, the tests it added, and the command that runs the suite | northwind-dispatch-portal; pull request 221; commit before: nwd-212-base; case branch: case/D-01; test added: Get_PendingDispatch_HasNoDriverName, in api.tests/DispatchesTests.cs; suite: dotnet test NorthwindDispatch.slnx |
| case.json | What run-case needs: the repository, the case branch, the setup and test commands, the allowed tools, and the reference files to copy in | repo, branch case/D-01, setup: dotnet restore and npm ci, test: dotnet test, reference files: api.tests/DispatchesTests.cs from pr-221-merged |
| reference.diff | The merged change, saved with git diff | One line in api/Controllers/DispatchesController.cs, a regression test, and a changelog entry |
| weak.diff | A reverted, reworked, or rejected Claude Code change for the same work. Leave it out if none exists | Pull request 219, reverted because it returned 404 for a dispatch that exists, and added a test asserting it |
| note.md | One or two lines: who approved the pull request, and what a reviewer checks that the tests do not | Backend lead approved. A pending dispatch returns 200, with driverName null. |

**Done when.** Two or three subfolders per target task, each with request.md, context.md, reference.diff, and note.md; a case branch pushed for each; and no secrets in any file.

**If you get stuck.** If a task has only one suitable pull request, bring it. A pull request without tests still counts: the reviewer's judgment becomes its grader. A task with no merged work worth copying may not be a good target; raise it in the workshop. If you cannot push branches to the shared repository, write the commit before in context.md; attendees create the branch in their own clone in the workshop.

## Step 4: Note usage so far · About 10 minutes

**Why it matters.** In Exercise 1 the team sets adoption and cost targets on the Exit Criteria tab from the foundation's own week-1 figures, with Anthropic's published figures beside them for comparison only. Without a starting point, a target is a guess.

### How to do it

1. Ask a Claude administrator, an Admin or Owner, to open the Claude Code analytics dashboard at claude.ai/analytics/claude-code, on Team and Enterprise plans. API customers use the Claude Console at platform.claude.com/claude-code.
2. From the Adoption chart, or the Activity chart in the Console, note daily active users in the foundation's first week and in the most recent week, and the number of seats assigned to it.
3. Contribution metrics (PRs with Claude Code) need a GitHub admin to install the Claude GitHub app. On Bitbucket, count merged pull requests with the Co-Authored-By trailer Claude Code adds to its commits instead, for the same two weeks, where the team keeps the trailer on.
4. From the spend report, exported from the organization's analytics settings, note the estimated spend for the engineers building the foundation since it began. Divide it by the sum of daily active users over the same days to get a cost per developer per active day.

### Example

> 24 seats; 18 daily active users in week 1 (75 percent). PRs with Claude Code: 48 percent, counted from Co-Authored-By trailers. About $16 per developer per active day.

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
Backend lead: bug fix from a Jira issue. QA lead: unit tests for changed code. Staff engineer: pull request review against the checklist.
```

**Done when.** The decision, and at least one expert for every target task, are written in the box below.

**If you get stuck.** One expert is enough to start. The presenter grades second, and the case is marked Expert and presenter until a second expert confirms it. If nobody can name the decision, write the most likely one; the workshop opens by agreeing it.

## Step 6: Check your access · About 10 minutes per attendee, up to an hour if tools need installing

**Why it matters.** In the workshop each attendee replays cases and grades each run with the pull request's tests. A sign-in problem or a test suite that will not run costs the whole group its time.

### How to do it

1. Get the workshop repository, as section 1.2 of its WALKTHROUGH-dotnet.md describes, and run: dotnet run --file templates/check-setup.cs. It checks git, the .NET SDK, Docker, disk space, and the run credential, changes nothing, and prints how to fix anything missing.
2. Create the credential for the runs, as section 1.4 describes: one you can revoke after the workshop. Then run the check with --live: it builds the run image (once; a few minutes) and makes one tiny real call from inside a run container (a few cents) to prove the runs can sign in.
3. Clone each repository you will work on, or confirm that you can.
4. For one of the collected pull requests, check that its tests run without services the container cannot start, such as SQL Server or Redis: in-memory providers and fakes are fine. Note the exact setup command (restore, npm ci) and test command for its case.json.
5. Note the exact test command. In the workshop it goes into the case's allow list, so Claude can run the tests without a permission prompt.

**Done when.** The check says All set, including the live check, and each attendee has confirmed the setup and test commands for one in-scope repository.

**If you get stuck.** If the runs cannot sign in, ask your Claude administrator for a seat that includes Claude Code, or for a workshop API key. If Docker is not allowed on a company laptop, ask your IT team, or use another computer. If a suite needs SQL Server, Redis, or other services, prefer a pull request whose tests run without them; otherwise give the case a services entry (section 10 of WALKTHROUGH-dotnet.md). Never put live secrets or connection strings in a case. If packages come from a private feed, give the feed credentials to the setup container with setupEnv or setupFiles (section 10). In a large solution, note the command that runs only the affected projects' tests.

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

Each run is a real model call on your plan or API account. Expect about ten runs per attendee in the session: in testing, a practice run cost about $0.10, so about $1 per attendee. Each run's output reports its cost, and the tracker records it. Anthropic's benchmark from enterprise deployments is about $13 per developer per active day.

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
- [ ] Every attendee has run check-setup.cs with --live (git, the .NET SDK, Docker, and a run credential that signs in inside the run container), and knows the setup and test commands for one repository

Questions? Contact your WWT presenter.

---

*Make a new world happen.*

*This file is generated from the same source as the Word version. Send corrections to your WWT presenter rather than editing it.*
