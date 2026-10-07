# Evaluate Claude Code on Your Own Work

**Claude Lab** · Participant workbook

*Turn your merged pull requests into evidence, run a baseline, and decide what to expand*

Claude Code Adoption Bootcamps · Workforce AI Practice · Level: Intermediate · Current as of 2 October 2026

## About this workbook

Work directly in this document during the session. Each exercise matches a segment of the agenda. Keep it afterwards: the finished pages are the record of what you decided.

### What you will leave with

- A foundation evaluation set built from merged pull requests, with a measured baseline
- Success and exit criteria, measured where the evidence exists
- A decision for each target task, with an owner
- A regression set to carry into expansion

### Agenda

| Time | Segment |
| --- | --- |
| 0:00–0:10 | Welcome and room check |
| 0:10–0:25 | What the foundation has to prove |
| 0:25–0:45 | Exercise 1: Choose target tasks and success criteria |
| 0:45–1:15 | Exercise 2: Write cases from real work |
| 1:15–1:25 | Break |
| 1:25–1:40 | Exercise 3: Calibrate |
| 1:40–2:15 | Exercise 4: Run the baseline |
| 2:15–2:25 | Break |
| 2:25–2:40 | Reading the result |
| 2:40–2:55 | Exercise 5: Decide and hand off |
| 2:55–3:00 | Readout and close |

---

## Exercise 1: Choose target tasks and success criteria

About 15 minutes. Complete the Target Tasks and Exit Criteria tabs in the tracker; use this page to draft if that is easier. Example row: Bug fix from a Jira issue | a regression test that fails before and passes after, and no unrelated changes | a change to the response schema | style comments only. Done when every target task has a row and every exit criterion has a target, before anyone has run a case.

| Target task | Owner (role) | What good output looks like: good enough to merge, and never acceptable | How often it happens |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

**Pass rate each target task must reach**

>

**Consistency bar: share of cases that must pass every run**

>

**Adoption targets, from the foundation's week-1 analytics**
*Daily active users against assigned seats; pull requests with Claude Code*

>

**Cost target**
*Anthropic's benchmark for comparison: about $13 per developer per active day on average, and under $30 for 90 percent of users*

>

---

## Exercise 2: Write cases from real work

About 24 minutes. Write each case directly into the Eval Cases tab of the tracker; use this page to draft if that is easier. Example row: Fix NWD-212: GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet | northwind-dispatch-portal, case branch case/D-01 | the merged tests pass, and a pending dispatch returns 200 with driverName null | a 404 for a dispatch that exists; an edited test | Bug fix from a Jira issue. Done when the group has six to ten cases, each naming its target task and reference pull request.

| Request, as an engineer would phrase it | Repository and commit before the pull request | Must include | Must not | Target task |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

- [ ] Each case names its target task
- [ ] Each case names the merged pull request as its reference output, and the tests it added
- [ ] Any weak, reverted, or rejected earlier output is kept with its case
- [ ] At least one case where the right response is to ask a question first
- [ ] Each case judges the result, not the steps taken

---

## Exercise 3: Calibrate

Two graders grade the same cases on the Calibration tab without discussing them: each case's reference output, and its weak output where one exists. Then compare. Rewrite any case where the verdicts differ or either grader chose 'can't tell', and grade the rewritten case again on a new row. Record whether both graders were domain experts. About 10 minutes. Done when every case graded has an agreed verdict or has been rewritten, and the agreement rate shows on the Calibration tab.

| Case ID | Why the verdicts differed | How the case was rewritten |
| --- | --- | --- |
|  |  |  |
|  |  |  |
|  |  |  |

**Agreement rate (from the Calibration tab)**

>

**Cases waiting for a second domain expert**

>

---

## Exercise 4: Run the baseline

About 28 minutes. Take one case per target task and run each three times with run-case, each run in its own container on its own clone. Record every run on the Runs tab, and read the diffs as well as grading them. Done when each of your cases has three graded runs on the Runs tab, or your group has agreed to step down to one run per case.

1. Check eval-run.json names the model your team uses day to day. Every run uses it, and every row records it.
2. Run each case with: run-case --eval-set `<eval-set>` --case `<case>`. It reads the case's case.json, runs all three in parallel, and prints rows to paste into the Runs tab. The steps below are what it does.
3. For each run, it clones only the case branch, with no tags, and removes the remote, so the merged fix is not in the clone's history. The clones live in a runs folder kept apart from eval-set.
4. It restores the packages in a setup container, then runs the request exactly as written with claude -p in a fresh container that sees only that clone, with the eval-run settings, --setting-sources project,local, --strict-mcp-config, --no-session-persistence, the case's allowed tools, and the model from eval-run.json.
5. It saves the reply, the diff, and git status to the outputs folder, copies in the pull request's tests, and runs the suite in a container that has no credential and no network. It copies the rows to your clipboard: paste them into the first empty row of the Runs tab, in column A.
6. Record the verdict: grade against Must include and Must not, Pass, Fail, or Can't tell. Choose Can't tell when the verdict depends on something the case does not say. The row already has the Claude Code version, the model, the cost, and the duration.
7. Note anything you saw in the diff that the verdict does not capture. If a row says the credential was found in an output, revoke it before the next run.

**Pass rate by target task (from the Summary tab)**

>

**Share of cases passing every run**

>

**Patterns noticed while reading diffs**

>

---

## Exercise 5: Decide and hand off

About 15 minutes, together on screen. Record a decision for each target task on the Decisions tab, and the measured value for each exit criterion. Done when every target task has one decision and an owner, and every exit criterion has a measured value or reads Not yet measured.

| Target task | Decision (expand / build a skill / improve the brief or CLAUDE.md / add a tool or MCP server / out of scope) | Why | Owner |
| --- | --- | --- | --- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

**Exit criteria met and not met**

>

**Regression set: cases that passed every run**

>

**Changes that trigger a regression run**
*Any change to CLAUDE.md, settings, a skill, a plugin, the Claude Code version, or the model*

>

---

## Reference

### What the foundation has to prove

- Two or three success measures, defined before results come in.
- Adoption, from the analytics dashboard: daily active users and sessions, pull requests with Claude Code, suggestion accept rate.
- Quality: the change is good enough to merge, and good every time, on the tasks that matter.
- Targets set from the foundation's own week-1 figures, with Anthropic's cost benchmarks beside them for comparison.
- Success criteria become exit criteria: each gets a target on the Exit Criteria tab, set before results come in.

### Anatomy of a case

- Request: phrased the way an engineer would ask, often the issue text.
- Repository and commit: the code as it was before the pull request, on a case branch.
- Must include: what a good result has to contain.
- Must not: what a good result must avoid.
- Target task: the kind of work the case belongs to.
- Reference output: the merged pull request, and the tests it added.
- Weak output: a reverted, reworked, or rejected earlier change, where one exists.

### One isolated run

- Where things live: the eval-set folder (tracker, case folders, outputs, eval-run.json and eval-run-settings.json) and any full-history clone stay outside the runs folder. Each run's container sees only that run's clone.
- Each case folder holds case.json: the repository, the case branch, the setup and test commands, the allowed tools, and the reference files to copy in before the test.
- One run: run-case --eval-set `<eval-set>` --case `<case>` --runs 1. Three runs: leave out --runs. After a first run, add more with --start 2 --runs 2.
- Each run: a single-branch clone with no tags and no remote; a setup container (restore, npm ci); claude -p in a fresh container with the run credential; the diff and status saved; the pull request's tests copied in and run in a container with no credential; the clone removed.
- Outputs, per run: `<case>`-run-N.md (the reply), .diff and .status (what changed), .json (cost, duration, model), .tests.txt (the test run), and `<case>`-runs.tsv with the rows for the Runs tab.
- The same command on Windows, macOS, and Linux: run-case is a wrapper around templates/run-case.cs, a .NET 10 file-based app.

### Passing once versus every time

- pass@k: at least one of k runs succeeds. pass^k: all k runs succeed.
- A case that passes 90 percent of runs passes all three of three runs about 73 percent of the time.
- At 75 percent per run, all three pass about 42 percent of the time.
- At 50 percent per run, all three pass about 13 percent of the time.

### From failure to fix

- Context the engineer knew but did not give: improve the brief, or add it to CLAUDE.md.
- A team standard Claude does not know: build a skill.
- Work Claude cannot reach: add a tool or an MCP server.
- Judgment Claude should not exercise: out of scope.

### After the workshop

- Finish any repeat runs, so every case has three graded runs.
- Ask a second domain expert to confirm every case marked Expert and presenter.
- Keep the cases that passed every run as the regression set. Re-run it before and after any change to CLAUDE.md, settings, a skill, a plugin, the Claude Code version, or the model.
- Take tasks marked build a skill to Workshop 2, Skills and Plugins for Engineering Teams, with their cases as the baseline. Once skills ship in a plugin, Workshop 5 · Established moves the cases into claude plugin eval.

### Glossary

- Foundation: the first stage of a Claude Code rollout, built to produce evidence for the expansion decision. Anthropic's cost guidance calls it a pilot group.
- Target task: a kind of engineering work Claude Code is meant to take on first, such as bug fixes from Jira issues.
- Brief: the request and context an engineer gives Claude Code.
- Eval case: one request with its standard, replayed against Claude Code. Capability cases ask whether Claude Code can do the work yet and are expected to start low. Regression cases passed every run and should keep passing; a failure means something changed.
- Case branch: a branch at the commit before the pull request, so a clone can stop there.
- Domain expert: someone who would approve or reject this work in a real review. Two-expert standard: two domain experts, grading separately, reach the same verdict. Expert and presenter: only one domain expert has graded the case so far.
- Run container: a fresh Docker container for one step of one run, which sees only that run's clone. The eval set, the full-history repository, and your home folder are not in it.
- Automatable grader: the part of the verdict a command can decide, usually the pull request's tests.
- Week 1: the foundation's first week of use, the baseline for the adoption and cost targets.
- Stuck: post the word stuck in chat during an exercise, and the presenter comes to you.
- Personal setup: what each engineer adds to Claude Code for themselves, kept in their home folder: plugins, hooks, MCP servers, a personal CLAUDE.md, and auto memory. The evaluation runs leave it out, so everyone measures the same Claude Code and no run can read notes an earlier run left behind.
- Plugin: a package of add-ons, such as skills and hooks, installed into Claude Code.
- Hook: a command Claude Code runs automatically at a set moment, such as when a session starts.
- MCP server: a connection that gives Claude Code tools for another system, such as an issue tracker.
- Auto memory: notes Claude Code saves between sessions and reads back at the start of the next one.
- Skill: a packaged set of instructions Claude Code loads for one kind of task, such as your team's testing conventions. Build a skill is one of the five decisions.
- Clone: a copy of a git repository, with its history, in a folder of its own.
- Branch: a named line of work in a repository. A case branch is one such name.
- Diff: the lines a change adds and removes, as git diff shows them: + for added, - for removed.

### Further reading

- Demystifying evals for AI agents — anthropic.com/engineering/demystifying-evals-for-ai-agents
- Track team usage with analytics — code.claude.com/docs/en/analytics
- Manage costs effectively — code.claude.com/docs/en/costs (cost benchmarks and starting baselines)
- Communications kit — code.claude.com/docs/en/communications-kit (announcement template for the first wave of users)
- Run Claude Code programmatically — code.claude.com/docs/en/headless
- Settings: setting sources, claudeMdExcludes, disableAllHooks, autoMemoryEnabled — code.claude.com/docs/en/settings-reference
- Test plugins with evals — code.claude.com/docs/en/plugin-evals
- Configure permissions — code.claude.com/docs/en/permissions (read-only commands and the working directories)
- Settings reference — code.claude.com/docs/en/settings-reference (permissions.blockReadsOutsideWorkingDirectories)

---

*Make a new world happen.*

*This file is generated from the same source as the Word version. Send corrections to your WWT presenter rather than editing it.*
