# Walkthrough (.NET and Angular): Evaluate Claude Code on Your Own Work

A step-by-step guide to **Claude Lab: Evaluate Claude Code on Your Own Work** for teams that build with .NET and Angular and already use Claude Code day to day. It follows the workshop agenda. Use it to follow along in a live session, to rehearse, or to work through the workshop on your own.

- **Track A, practice on Northwind Dispatch:** every step below. You work on a fictional ASP.NET Core 10 and Angular 19 codebase with six ready-made practice cases, and check your work against [demo/dotnet-angular/ANSWERS.md](demo/dotnet-angular/ANSWERS.md).
- **Track B, your own repositories:** do [Setup](#1-setup) and the pre-work ([markdown](ccw5gd-pre-work.md) · [Word](ccw5gd-pre-work.docx)) first, then follow each exercise. Where you see the 🅱 note, use your own pull requests. [Section 10](#10-track-b-doing-it-on-your-own-repositories) collects the differences.

**Who it's for:** engineers who are comfortable in a terminal, git, and their own stack. It runs on **Windows (PowerShell), WSL, macOS, and Linux**. For a guide that assumes no terminal experience, with a Python practice kit, see [WALKTHROUGH.md](WALKTHROUGH.md).

**Time:** about 3 hours, the length of the workshop. Setup takes 15–30 minutes, most of it Docker and the first image build.
**Cost:** Exercise 4 makes real Claude Code calls, billed to your organization's account. In testing, a practice run cost about $0.10 on Sonnet. Six runs (two cases, three runs each) is the workshop's standard load. Each run's JSON output reports its exact cost.

**A word you'll see throughout: the *foundation*.** It's the first group of engineers and target tasks your organization uses to prove Claude Code before rolling it out more widely, which Anthropic calls a pilot group. This workshop measures what the foundation can hand to Claude Code.

**What's different from the Python kit.** Every run happens in its own **Docker container that sees only that run's clone**, so nothing a run executes can reach the answers. Each run also leaves your personal Claude Code setup out, so the baseline is the same for everyone. [Section 7](#7-exercise-4-run-the-baseline) explains both.

## Contents

0. [How the walkthrough maps to the workshop](#0-how-the-walkthrough-maps-to-the-workshop)
1. [Setup](#1-setup)
2. [Welcome and room check](#2-welcome-and-room-check)
3. [What the foundation has to prove](#3-what-the-foundation-has-to-prove)
4. [Exercise 1: Choose target tasks and success criteria](#4-exercise-1-choose-target-tasks-and-success-criteria)
5. [Exercise 2: Write cases from real work](#5-exercise-2-write-cases-from-real-work)
6. [Exercise 3: Calibrate](#6-exercise-3-calibrate)
7. [Exercise 4: Run the baseline](#7-exercise-4-run-the-baseline)
8. [Reading the result](#8-reading-the-result)
9. [Exercise 5: Decide and hand off](#9-exercise-5-decide-and-hand-off)
10. [Track B: doing it on your own repositories](#10-track-b-doing-it-on-your-own-repositories)
11. [Clean up](#11-clean-up)
12. [Troubleshooting](#12-troubleshooting)

---

## 0. How the walkthrough maps to the workshop

| Workshop time | Segment | Slides | Workbook | Here |
|---|---|---|---|---|
| 0:00–0:10 | Welcome and room check | 1–3 | — | [§2](#2-welcome-and-room-check) |
| 0:10–0:25 | What the foundation has to prove | 4–8 | Reference: What the foundation has to prove | [§3](#3-what-the-foundation-has-to-prove) |
| 0:25–0:45 | Exercise 1 | 9–11 | Exercise 1 | [§4](#4-exercise-1-choose-target-tasks-and-success-criteria) |
| 0:45–1:15 | Exercise 2 | 12–15 | Exercise 2 | [§5](#5-exercise-2-write-cases-from-real-work) |
| 1:15–1:25 | Break | | | |
| 1:25–1:40 | Exercise 3 | 16–17 | Exercise 3 | [§6](#6-exercise-3-calibrate) |
| 1:40–2:15 | Exercise 4 | 18–21 | Exercise 4 | [§7](#7-exercise-4-run-the-baseline) |
| 2:15–2:25 | Break | | | |
| 2:25–2:40 | Reading the result | 22–23 | Reference: From failure to fix | [§8](#8-reading-the-result) |
| 2:40–2:55 | Exercise 5 | 24 | Exercise 5 | [§9](#9-exercise-5-decide-and-hand-off) |
| 2:55–3:00 | Readout and close | 25–26 | Reference: After the workshop | [§9](#9-exercise-5-decide-and-hand-off) |

Keep the deck ([ccw5gd-slides.pptx](ccw5gd-slides.pptx)) and the workbook ([markdown](ccw5gd-participant-workbook.md) · [Word](ccw5gd-participant-workbook.docx)) open alongside this page. The workbook's Reference section, which ends with a glossary, defines every term used here.

---

## 1. Setup

You do this once, before the session. Commands use `$HOME`, which PowerShell, bash, and zsh all expand, so most of them are the same in every shell. Where they differ, there is a block for each.

### 1.1 What you need

| You need | Why | Notes |
|---|---|---|
| **Windows 10/11, macOS 13+, or Linux**; WSL works too | Where you run the harness | Native Windows is fine: no WSL needed |
| **git** 2.28 or later | Clones the practice history and each run | On Windows, also run `git config --global core.longpaths true` |
| **.NET 10 SDK** | Runs the harness (`run-case.cs`) and the setup check | [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download). You don't need Node on your computer: the tests run inside the container |
| **Docker** running **Linux containers**, with 6 GB of memory or more | Every run happens in its own container | Docker Desktop on Windows and macOS; Docker Engine, or Docker Desktop's WSL integration, on Linux and WSL |
| About **8 GB of free disk** | The run image is about 2 GB; each run's clone about 400 MB while it runs | |
| **Claude Code** 2.1.257 or later | To create the run credential (`claude setup-token`) | The runs use their own pinned copy inside the container |
| A **credential for the runs** that you can revoke afterwards | Each container signs in with it | See [1.4](#14-create-a-credential-for-the-runs) |
| **Excel** (or LibreOffice) | The evaluation tracker | |
| *Track B only:* merged pull requests for each target task, and a reviewer who can judge them | They are the cases you measure | The [pre-work](ccw5gd-pre-work.md) |

### 1.2 Get this repository

```bash
git clone https://github.com/WWT-AINE-Workshops/workshop-evaluate-claude-code "$HOME/ccw5g"
```

The rest of this guide uses `$HOME/ccw5g`. On Windows, clone it wherever you like on a local drive (not a network share), and adjust the paths.

### 1.3 Check what you have

```bash
dotnet run --file "$HOME/ccw5g/templates/check-setup.cs"
```

The first run compiles the check, which takes a few seconds. Each line starts with `[ ok ]`, `[warn]`, or `[FIX ]`, and each `[FIX ]` says exactly what to do. Repeat until it ends with `All set.`

### 1.4 Create a credential for the runs

Each run's container signs in on its own, with a credential passed in through the environment. Be clear about what that means: **code a run executes can read the credential, and the container can reach the network.** A test Claude writes, or a package's install script, could find the token and send it anywhere. In testing, Claude Code removed the variable from the commands it ran, but test code could still read it from the running Claude process. So **use a credential you can cut off after the workshop**, billed to your organization as usual, and prefer the shortest-lived one your organization allows. Pick one:

- **A setup-token on your own seat.** Run `claude setup-token`, sign in, and copy the token it prints. It is valid for one year. Claude Code's documentation doesn't describe revoking a single token, so if one leaks, tell your Claude administrator straight away. Then save it where the harness looks for it. Nothing appears while you paste:

  bash or zsh:
  ```bash
  mkdir -p ~/.config/ccw5g && chmod 700 ~/.config/ccw5g
  read -rs T && printf '%s' "$T" > ~/.config/ccw5g/claude-oauth-token && unset T && chmod 600 ~/.config/ccw5g/claude-oauth-token
  ```
  PowerShell (5.1 or 7):
  ```powershell
  New-Item -ItemType Directory -Force "$HOME\.config\ccw5g" | Out-Null
  $t = Read-Host -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($t)) | Set-Content -NoNewline "$HOME\.config\ccw5g\claude-oauth-token"; Remove-Variable t
  ```
- **An API key** your administrator issues for the workshop, in a Console workspace with a spend limit, which the administrator can disable afterwards. Set it in the terminal you run cases from: `export ANTHROPIC_API_KEY=…` in bash or zsh, `$env:ANTHROPIC_API_KEY = "…"` in PowerShell.
- **Your organization's Amazon Bedrock, Google Cloud, or Microsoft Foundry setup.** Set its variables in that terminal. For Bedrock: `CLAUDE_CODE_USE_BEDROCK=1`, `AWS_REGION`, and **short-lived credentials** from your SSO login. `aws configure export-credentials --format env` (bash or zsh) or `--format powershell` (PowerShell) prints them, including `AWS_SESSION_TOKEN`, and they expire on their own. Your `~/.aws` profile isn't visible inside the container, so the credentials must be in the terminal's environment. If your organization pins models with `ANTHROPIC_MODEL` or `ANTHROPIC_DEFAULT_SONNET_MODEL` (for an inference profile), set those too: run-case passes them through.

If more than one is set, the runs use the same order Claude Code does: a cloud provider, then `ANTHROPIC_AUTH_TOKEN`, then `ANTHROPIC_API_KEY`, then `CLAUDE_CODE_OAUTH_TOKEN`, then the token file. Every `run-case` prints the one it uses, as `Signing in with …`. Check it, especially if your terminal profile already sets an API key or Bedrock. On Windows, the token file sits in your profile folder, which only your account can read by default.

Never paste a credential into a chat, a case, or a shared screen. The harness replaces any output file that contains it, and tells you to revoke it.

### 1.5 Put `run-case` on your PATH

`run-case` is a wrapper around `templates/run-case.cs`. Add the folder to your PATH for this terminal.

bash or zsh (add the line to `~/.zshrc` or `~/.bashrc` to keep it):
```bash
export PATH="$HOME/ccw5g/templates:$PATH"
```
PowerShell (add the line to `$PROFILE` to keep it):
```powershell
$env:PATH = "$HOME\ccw5g\templates;$env:PATH"
```

Check it with `run-case --help`.

### 1.6 Know where things live

| Folder | What's in it | Who reads it |
|---|---|---|
| `$HOME/ccw5g` | This repository: slides, workbook, templates, the demo kits | You |
| `$HOME/nwd-foundation` | The practice repository **with its full history**, and `eval-set/`: case files, reference answers, outputs, your tracker | You and the graders. **Never a run** |
| `$HOME/eval-runs` | One clone per run, which stops at the case branch. Each is mounted into that run's containers and removed afterwards | The run, and nothing else |

### 1.7 Build the practice repository

The practice repository's history ships as one git bundle. Clone it, make every branch local, and drop the link back to the bundle:

```bash
git clone "$HOME/ccw5g/demo/dotnet-angular/northwind-dispatch.bundle" "$HOME/nwd-foundation/northwind-dispatch-portal"
git -C "$HOME/nwd-foundation/northwind-dispatch-portal" fetch origin "+refs/heads/*:refs/heads/*" --update-head-ok
git -C "$HOME/nwd-foundation/northwind-dispatch-portal" remote remove origin
git -C "$HOME/nwd-foundation/northwind-dispatch-portal" log --oneline --graph --decorate --all
```

The `fetch` prints one `[new branch]` line per branch. Then you should see this graph, with the same commit hashes (the history is built with fixed dates, so they match on every machine):

```text
* 7c18bd6 (pr-251) docs: add request examples to docs/api.md (#251)
| * 80e6371 (pr-250, case/D-05) feat: export dispatches as CSV (#250)
|/
* d25eb62 (HEAD -> main, tag: pr-244-merged, case/D-06) fix: cancelling a dispatch requires a dispatcher (#244)
| * 4834fc0 (tag: pr-242-weak) test: cancel endpoint (#242)
|/
* 63c1aae (tag: pr-231-merged, case/D-04) fix: dispatch search shows results for the latest query (NWD-230) (#231)
| * 3204c9c (tag: pr-229-weak) fix: debounce the dispatch search (NWD-230) (#229)
|/
* ecf1227 (tag: pr-224-merged, case/D-02) test: cover the dispatch list filter and sort (#224)
* dc788e7 (tag: pr-221-merged, case/D-03) fix: look up a dispatch that has no driver yet (NWD-212) (#221)
* 73aef82 Revert "fix: dispatch lookup no longer returns a 500 (NWD-212) (#219)"
* fe93ac8 (tag: pr-219-weak) fix: dispatch lookup no longer returns a 500 (NWD-212) (#219)
* f611c01 (tag: nwd-212-base, case/D-01) refactor: load the dispatch with its driver on lookup (#215)
* e8adb5c (tag: v2.2.0) chore: release 2.2.0
```

Then the eval set, and the settings file every run uses:

bash or zsh:
```bash
cp -R "$HOME/ccw5g/demo/dotnet-angular/eval-set" "$HOME/nwd-foundation/eval-set"
cp "$HOME/ccw5g/templates/eval-run-settings.json" "$HOME/nwd-foundation/eval-set/"
```
PowerShell:
```powershell
Copy-Item -Recurse "$HOME\ccw5g\demo\dotnet-angular\eval-set" "$HOME\nwd-foundation\eval-set"
Copy-Item "$HOME\ccw5g\templates\eval-run-settings.json" "$HOME\nwd-foundation\eval-set\"
```

> **Don't read `eval-set/` yet.** It holds the finished cases, so it's the answer key for Exercise 2.

### 1.8 Build the run image, and check the runs can sign in

```bash
dotnet run --file "$HOME/ccw5g/templates/check-setup.cs" -- --live
```

It builds `ccw5g-eval-run:2.1.285` the first time, which takes a few minutes. The image holds the .NET 10 SDK, Node 22, git, and Claude Code 2.1.285. It then makes one tiny real call from inside a container. You want `[ ok ]  Claude Code signs in inside the run container`.

### 1.9 Copy the tracker

Copy `templates/foundation-evaluation-tracker.xlsx` into `$HOME/nwd-foundation/eval-set/` and open the copy. Every exercise's results go there. Its **Read Me** tab explains each tab. Row 4 of every tab is a grey example that the calculations skip: start on row 5. Choose **Enable Editing** if Excel opens it in Protected View.

> 🅱 **Track B:** your coordinator has made an `eval-set` folder for your team, as [pre-work](ccw5gd-pre-work.md) Step 1 describes. Use that folder and its tracker instead.

---

## 2. Welcome and room check

*Slides 1–3.*

1. Read slide 2 (what you will leave with) and slide 3 (the agenda).
2. Note the Claude Code version the runs use: **2.1.285**, from the image. It goes on every row of the Runs tab, and `run-case` fills it in for you.
3. **Working agreements:** every run happens in its own container on its own clone; nobody pushes to a shared branch; credentials and confidential data stay out of anything you share.

---

## 3. What the foundation has to prove

*Slides 4–8, 15 minutes. Workbook: Reference, "What the foundation has to prove".*

Five ideas to take with you:

1. **Decide the evidence before you see it.** Name the decision the foundation supports and who makes it. Criteria written after the results tend to fit the results.
2. **Adoption is not quality.** Your team has used Claude Code for a long time, so the dashboard already shows high use. It can't show whether the changes were right. Today is about quality: is the change good enough to merge, every time?
3. **Benchmarks are for comparison, not targets.** Anthropic publishes about $13 per developer per active day on average. Set your own targets from your own figures.
4. **Start evaluating now.** Twenty to fifty cases drawn from real work is a strong start. Today each group builds six to ten; the practice kit uses six.
5. **Most foundation cases are capability cases** (can Claude Code do this yet?). The ones that pass every run become the regression set: the cases you re-run whenever CLAUDE.md, a skill, the model, or the Claude Code version changes.

**Try it:** write one sentence naming the decision your foundation supports and who makes it. For Northwind Dispatch: *"Which engineering tasks the dispatch team hands to Claude Code by default, decided by the engineering manager."*

---

## 4. Exercise 1: Choose target tasks and success criteria

*Slides 9–11. About 15 minutes. Workbook Exercise 1. Tracker: **Target Tasks** and **Exit Criteria** tabs.*

A good target task is work engineers do often, where a test or a reviewer can judge the output, and where merged pull requests show what good looks like.

**Northwind Dispatch targets three tasks.** Enter them on the **Target Tasks** tab, rows 5–7, with names spelled *exactly* like this (the Summary matches cases to tasks by name):

| Target task | Owner (role) | What good output looks like (you write this) |
|---|---|---|
| Bug fix from a Jira issue | Backend lead | ? |
| Unit tests for changed code | QA lead | ? |
| Pull request review against the checklist | Staff engineer | ? |

Then:

1. For each task, write **What good output looks like** in one or two lines a reviewer would agree with. The repository's `CLAUDE.md`, `docs/review-checklist.md`, and `api.tests/DispatchApiFactory.cs` (in `$HOME/nwd-foundation/northwind-dispatch-portal`) are worth a look first.
2. On the **Exit Criteria** tab, set a target for each criterion **before any result exists**. The pass-rate target (row 5) applies to each target task separately. Northwind Dispatch's fictional week-1 analytics: 24 seats, 18 daily active users (75%), 48% of pull requests with Claude Code, and about $16 per developer per active day.

- **Done when** three target tasks have a row each and every exit criterion has a target.
- **Compare:** [ANSWERS.md §1](demo/dotnet-angular/ANSWERS.md#1-exercise-1-target-tasks-and-exit-criteria).

> 🅱 **Track B:** confirm the three to five target tasks from your pre-work. Work your team has no specialist for, such as T-SQL changes or CloudFormation templates, can be a valuable target, but plan how you'll grade it: a reviewer with that expertise has to be in the room for Exercise 3.

---

## 5. Exercise 2: Write cases from real work

*Slides 12–15. About 24 minutes. Workbook Exercise 2. Tracker: **Eval Cases** tab.*

A case is a request, phrased as an engineer would ask it, plus the code as it was before the pull request, what a good result must include, what it must not do, and its target task. The merged pull request is the reference output.

### 5.1 Explore Northwind Dispatch's work

```bash
cd "$HOME/nwd-foundation/northwind-dispatch-portal"
git show --stat pr-221-merged
git diff nwd-212-base pr-221-merged
```

Pull request 221 changes three files: the controller (one line), `api.tests/DispatchesTests.cs` (a new regression test), and `CHANGELOG.md`. In the graph from [1.7](#17-build-the-practice-repository): tags mark merged and weak pull requests, `pr-250` and `pr-251` are open pull requests, and each `case/D-0N` branch sits at the commit before its pull request. The review cases are the exception: `case/D-05` sits on pull request 250 itself, and `case/D-06` on `main`, with both open pull requests copied in.

| Pull request | Status | Jira issue or description | Approved or reviewed by |
|---|---|---|---|
| #221 (`pr-221-merged`) | Merged | NWD-212: "GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet. Pending dispatches don't have a driver until a dispatcher assigns one." | Backend lead |
| #219 (`pr-219-weak`) | Merged, then reverted (#220) | An early fix for NWD-212, written with Claude Code | Reverted by the backend lead |
| #224 (`pr-224-merged`) | Merged | "Write tests for the dispatch list's status filter and sort." | QA lead |
| #231 (`pr-231-merged`) | Merged | NWD-230: "The dispatch search sometimes shows results for an earlier query. Type 'Po', pause, then 'Portland': when the first request is slow, its results win." | Frontend lead |
| #229 (`pr-229-weak`) | Closed, not merged | An early fix for NWD-230, written with Claude Code. Its CI was green | Rejected by the frontend lead |
| #244 (`pr-244-merged`) | Merged | Cancelling a dispatch requires a dispatcher, with its tests | QA lead |
| #242 (`pr-242-weak`) | Closed, not merged | "Add tests for the cancel endpoint", first attempt, written with Claude Code | Rejected by the QA lead |
| #250 (branch `pr-250`) | Open | "feat: export dispatches as CSV". The staff engineer's review blocked it | Staff engineer |
| #251 (branch `pr-251`) | Open | "docs: add request examples to docs/api.md" | — |

### 5.2 Write six cases

On the **Eval Cases** tab, write one row per case, **D-01 to D-06**:

- Two cases for each target task, from the table above. At least one should be in the Angular app.
- At least one case where the right response is to **ask a question first**. Hint: someone asks for a review while two pull requests are open.
- Write the **request** as the engineer would have typed it, usually the Jira text.
- Write **Must include** and **Must not** in words a reviewer could apply. Ask yourself what a bad fix could get away with, *including one whose tests pass*.
- Record any **weak output** with its case.
- Fill in the **Automatable grader** column: the merged pull request's tests, the tests on the fixed code, or reviewer judgment.

**Compare:** browse [demo/dotnet-angular/eval-set/](demo/dotnet-angular/eval-set/) and [ANSWERS.md §2](demo/dotnet-angular/ANSWERS.md#2-exercise-2-the-six-cases). Each case folder also holds a `case.json`, the machine-readable options that `run-case` uses.

> 🅱 **Track B:** write cases from your team's pull requests, and a `case.json` for each ([§10](#10-track-b-doing-it-on-your-own-repositories)).

---

## 6. Exercise 3: Calibrate

*Slides 16–17. About 10 minutes. Workbook Exercise 3. Tracker: **Calibration** tab.*

The standard: two domain experts, grading separately, reach the same verdict. If graders disagree, the case is unclear, so rewrite the case, not the grader.

Four cases have both a reference output and a weak one: **D-01, D-02, D-04, and D-06**, in `$HOME/nwd-foundation/eval-set/D-0N/` (`reference.diff` and `weak.diff`, or `reference.md` and `weak.md` for D-06).

1. Grade each reference and weak output against *your* Must include and Must not: Pass, Fail, or Can't tell.
2. On the **Calibration** tab, add one row per output, with you as Grader A.
3. Open [ANSWERS.md §3](demo/dotnet-angular/ANSWERS.md#3-exercise-3-calibration), which plays **Grader B**. Set "Both domain experts?" to **No**.
4. Where verdicts differ, rewrite the case on the Eval Cases tab and grade it again on a new row.

- **The lesson most people find here:** D-02's weak fix debounces the search. Its tests are green and the diff looks reasonable, so a case that says only "fix the stale results" lets it pass. The race is still there.

---

## 7. Exercise 4: Run the baseline

*Slides 18–21. About 28 minutes. Workbook Exercise 4. Tracker: **Runs** tab.*

You now measure what Claude Code does today. **The baseline is Claude Code as installed, with the repository's own CLAUDE.md and settings.** No skill is needed.

**Set the model first.** `$HOME/nwd-foundation/eval-set/eval-run.json` names the model every run uses (`"sonnet"` by default). Set it to the model your team uses day to day, and keep it fixed for the whole evaluation. An alias such as `sonnet` moves to a newer model when Anthropic releases one, so for an evaluation that spans weeks, use the full model ID instead. On Bedrock, use the model or inference profile your account has enabled. A fresh container otherwise uses your account's default, which may not be what your engineers use.

### Why the runs are isolated this way

Anthropic has seen Claude gain an unfair advantage in its own evaluations by reading the git history of earlier trials. Each layer here closes a way the answer could leak in:

1. **The clone stops at the case branch.** Each run gets a single-branch clone with no tags and no remote, so the fix isn't in its history.
2. **The run's container sees only that clone.** Claude Code's `permissions.blockReadsOutsideWorkingDirectories` refuses *Claude's own* reads outside the folder, but not the programs a run starts. In testing, a test file run by `npm test` read the answer key straight through it. A container that never mounts the eval set closes that gap: inside it, `$HOME/nwd-foundation` doesn't exist.
3. **Your personal setup is left out.** Each run passes `--setting-sources project,local --strict-mcp-config --no-session-persistence`, and the settings file turns off hooks and auto memory. In testing, a user-level plugin wrote one run's results into the run folder, and its start-up hook fed them to the next run. These flags stop that, and they make every attendee's baseline the same. Your team's *shared* setup, committed to the repository, still loads.
4. **The tests run in a separate container with no credential**, after Claude has finished.

### 7.1 One run, then look at what happened (case D-01)

```bash
run-case --eval-set "$HOME/nwd-foundation/eval-set" --case D-01 --runs 1
```

The first run compiles the harness, then:

1. clones `case/D-01` into `$HOME/eval-runs/D-01-run-1`;
2. restores the NuGet and npm packages in a setup container;
3. runs `claude -p` in a fresh container;
4. captures the diff;
5. copies in the merged pull request's `api.tests/DispatchesTests.cs` and runs the API suite in a test container;
6. prints one row for the Runs tab and removes the clone.

On macOS it takes about a minute. On Windows, expect longer for the first run: `npm ci` writes about 40,000 files through Docker's file sharing, and antivirus scanning slows that down. The outputs are in `$HOME/nwd-foundation/eval-set/outputs/`:

| File | What it is |
|---|---|
| `D-01-run-1.md` | Claude's reply |
| `D-01-run-1.diff`, `.status` | What it changed, new files included |
| `D-01-run-1.json` | The full result: cost, duration, model, and any denied tool calls |
| `D-01-run-1.tests.txt` | The reference test run |
| `D-01-runs.tsv` | The row to paste into the Runs tab |

Judge the diff against `D-01/note.md`. Does a pending dispatch now return 200 with `driverName` null? Is the change confined to the lookup? Are existing tests untouched? Then paste the row into the **Runs** tab and type your verdict.

### 7.2 See the isolation for yourself (optional, no cost)

```bash
docker run --rm ccw5g-eval-run:2.1.285 ls -la /work /home/runner
```

That's everything a run's container holds besides the toolchains: an empty `/work` (where the run's clone is mounted) and a fresh home folder. Your home folder, the eval set, and your Claude Code configuration aren't there.

### 7.3 Three runs per case

Passing once is not passing every time. A case that passes three times in four passes all three of three runs only about 42% of the time, so each case gets three runs. Finish D-01 with runs 2 and 3, then run one case that contrasts with it:

```bash
run-case --eval-set "$HOME/nwd-foundation/eval-set" --case D-01 --start 2 --runs 2
run-case --eval-set "$HOME/nwd-foundation/eval-set" --case D-02
```

| Case | Kind | What run-case grades for you | What you still read |
|---|---|---|---|
| D-01 | Bug fix (API) | Copies in the merged tests, runs the API suite | The .diff: scope, the contract, no edited tests |
| D-02 | Bug fix (Angular) | Copies in the merged spec, whose race test makes the earlier response arrive last | The .diff: does it drop the earlier request? |
| D-03 | Tests for working code | Runs the suite as Claude left it | The .diff: one test per sort value plus the 400, the fixture conventions |
| D-04 | Tests that must catch a bug | Runs Claude's tests on the buggy code (should fail), then with the fixed controller (should pass) | The .diff: is there a 403 test for a customer? |
| D-05, D-06 | Review | Nothing (review case) | The reply (.md): did it flag the export route (D-05), and did it ask which pull request (D-06)? |

1. Paste the printed rows into the **Runs** tab (or open `outputs/<case>-runs.tsv`). The Verdict column is empty on purpose.
2. Read each run's outputs and type **Pass, Fail, or Can't tell**. Passing tests are necessary, not sufficient: a run that edits a test to make it pass is a Fail.
3. While one case runs, read the last one's diffs in a second terminal window: `run-case` holds the one it runs in. Note what a verdict misses in **What we noticed**.

- **Done when** each of your cases has three graded runs on the Runs tab.
- **Going further:** run all six cases, 18 runs. In testing, runs cost $0.06 to $0.11 each, so that's around $1.50.

> 🅱 **Track B:** each case's `case.json` holds your repository's setup and test commands ([§10](#10-track-b-doing-it-on-your-own-repositories)). The command is the same.

---

## 8. Reading the result

*Slides 22–23. About 15 minutes. Workbook: Reference, "From failure to fix". Tracker: **Summary** tab.*

Open the **Summary** tab. It calculates everything from your Eval Cases, Runs, and Calibration rows.

1. **Read it by target task**, not overall. An overall pass rate hides different stories.
2. **Consistency:** the cases with **Passed every run = Yes** are your first regression set.
3. **Name the likely fix for every failing case** on the **Decisions** tab:

   | What the failure shows | Likely fix |
   |---|---|
   | Context the engineer knew but didn't give | Improve the brief, or add it to CLAUDE.md |
   | A team standard Claude doesn't know | Build a skill |
   | Work Claude can't reach: Jira, logs, the database | Add a tool or MCP server |
   | Judgment Claude shouldn't exercise | Out of scope |

4. **Before you call anything a pass:** trace every file, method, and package in the output back to the repository. A changed test is still the most common way a bad fix gets through, and green CI is not a verdict.

**These results leave personal setup out.** If your engineers rely on their own CLAUDE.md, skills, or MCP servers, their everyday results may differ. To measure the team's shared setup, commit it to the repository on a branch, point the cases at that branch, and run them again. The difference is the setup's measured value.

**How much six runs can tell you.** Two cases and six runs per target task is a first look, not a verdict: one run more or less moves a task's rate by about 17 points. Treat a task that clears its target by a run or two as a candidate, and grow its cases toward the twenty to fifty Anthropic calls a strong start before the expansion is final.

**Compare:** [ANSWERS.md §4](demo/dotnet-angular/ANSWERS.md#4-reading-the-result) walks through a full, fictional set of 18 runs on these six cases.

---

## 9. Exercise 5: Decide and hand off

*Slides 24–26. About 15 minutes, then a 5-minute readout. Workbook Exercise 5. Tracker: **Decisions** and **Exit Criteria** tabs.*

1. For each target task, choose **one** decision on the **Target Tasks** tab, and record why on the **Decisions** tab, with an owner: Ready to expand · Build a skill · Improve the brief or CLAUDE.md · Add a tool or MCP server · Out of scope.
2. On **Exit Criteria**, rows 5, 6, and 9 calculate themselves. Fill in the others. Northwind Dispatch's fictional week-4 analytics: daily active users 83%, pull requests with Claude Code 58%, cost $16 per developer per active day.
3. **Readout:** the target tasks measured, the pass rate by task, the share of cases passing every run, which exit criteria are met, and the decision and owner for each task.

- **Compare:** [ANSWERS.md §5](demo/dotnet-angular/ANSWERS.md#5-exercise-5-decisions).

**After the workshop:**

- Keep the cases that passed every run as the regression set. Re-run it before and after any change to CLAUDE.md, settings, a skill, a plugin, the Claude Code version (the image's version), or the model.
- Tasks marked *Build a skill* go to **Workshop 2, Skills and Plugins for Engineering Teams**, with their cases as the baseline. Once skills ship in a plugin, **Workshop 5 · Established** moves the cases into `claude plugin eval`. Both are later sessions in WWT's Claude Code track: Workshop 2 builds and validates skills, and Workshop 5 · Established measures skills and plugins already in use.
- Revoke the credential you used for the runs.

---

## 10. Track B: doing it on your own repositories

Everything above works the same on your own code. Your team prepares the inputs with the pre-work ([markdown](ccw5gd-pre-work.md) · [Word](ccw5gd-pre-work.docx)). What changes:

| Northwind Dispatch (Track A) | Your repositories (Track B) |
|---|---|
| The bundle builds the history | Your Bitbucket repository; push a case branch at each pull request's commit before: `git push origin <commit before>:refs/heads/case/<ID>`. Check first that a `case/*` branch won't start Bitbucket Pipelines or match a deployment rule; if it would, push the case branches to a fork |
| `eval-set/D-0N/case.json` already written | Write one per case (below) |
| `$HOME/nwd-foundation/eval-set` | Your team's `eval-set` folder, outside every repository |
| The merged tests in the practice repository | `referenceRepo`: a full-history clone of your repository, kept **outside** `$HOME/eval-runs` |
| Answer key in ANSWERS.md | Your domain experts, grading separately |
| Fictional analytics | Your analytics dashboard (pre-work Step 4) |

A `case.json` for a bug fix in your API, with a full-history clone of the repository in a `repos` folder beside the eval set (the reference files come from the same clone, so `referenceRepo` isn't needed):

```json
{
  "case": "B-01",
  "repo": "../repos/<repository>",
  "branch": "case/B-01",
  "request": "request.md",
  "setup": "dotnet restore Your.sln && npm --prefix client ci",
  "test": "dotnet test Your.sln --filter FullyQualifiedName~Orders",
  "allow": ["Bash(dotnet test *)", "Bash(dotnet build *)"],
  "referenceRef": "<merged commit or tag>",
  "referenceFiles": ["tests/Orders.Tests/OrderLookupTests.cs"]
}
```

Paths in `case.json` are relative to the eval-set folder. For a test-writing case, put the fixed source files in `referenceFiles` and add `"checkBefore": true`. For a review case, leave out `setup` and `test`, and allow read-only git (`Bash(git log *)`, `Bash(git show *)`, `Bash(git diff *)`). `repo` can be a clone URL, but a local full-history clone is faster: each run clones from it. For an "ask first" review case with several open pull requests, list their branches in `extraBranches`, and run-case copies them into each run's clone (as D-06 does).

Things to watch on real code:

- **Tests that need SQL Server, Redis, or other services** can't start them inside the run container, which has no Docker of its own. Pick pull requests whose tests run in memory (SQLite, EF's in-memory provider, fakes), or grade those cases by review. Never put live connection strings or secrets in a case.
- **Private package feeds** (CodeArtifact, Azure Artifacts, ProGet): give the credentials to the setup container only, never to Claude's. In `case.json`, `setupEnv` names environment variables to pass through, such as `"setupEnv": ["CODEARTIFACT_AUTH_TOKEN"]`. `setupFiles` mounts files read-only, such as `"setupFiles": {"nuget.config": "/home/runner/.nuget/NuGet/NuGet.Config"}` with the file kept in the eval set. Restored packages go to the shared package cache, which Claude's container reads but cannot change. If a run adds a new package, its restore fails without the feed: that's expected.
- **AWS credentials stay out.** The containers don't see your `~/.aws`, so a run can't reach your AWS accounts. That's on purpose: keep it that way, and grade CloudFormation and infrastructure changes by review.
- **Jira:** use the issue text as the request. If a failure shows Claude needed the issue's history or comments, that's evidence for *Add a tool or MCP server*.
- **Large solutions:** use a `test` command that runs only the affected projects, and keep `allow` matching it.
- Your code stays with your team. Nothing is sent to WWT.

---

## 11. Clean up

Copy your tracker somewhere else first if you want to keep it: it lives inside `$HOME/nwd-foundation`. Then:

```bash
docker image rm ccw5g-eval-run:2.1.285
docker volume rm ccw5g-nuget ccw5g-npm
```

Delete the `$HOME/nwd-foundation` and `$HOME/eval-runs` folders (`rm -rf` in bash or zsh, `Remove-Item -Recurse -Force` in PowerShell), and **revoke the credential** you created for the runs.

---

## 12. Troubleshooting

| Symptom | Fix |
|---|---|
| `run-case: command not found`, or not recognized | Put the templates folder on your PATH ([1.5](#15-put-run-case-on-your-path)), or run `dotnet run --file "$HOME/ccw5g/templates/run-case.cs" -- <options>` |
| `Docker isn't running` | Start Docker Desktop (or the Docker service) and wait until it's ready |
| `no credential for the runs` | Save a setup-token ([1.4](#14-create-a-credential-for-the-runs)), or set `ANTHROPIC_API_KEY` or your cloud provider's variables in this terminal |
| A row says `Run failed`, and the `.stderr` mentions sign-in or 401 | The credential has expired or been revoked. Make a new one and run `check-setup.cs --live` |
| A row says `Setup failed` | Read `<case>-run-N.setup.txt`. Usually a package feed the container can't reach |
| `cloning case/D-0N ... failed` | The practice repository has only `main`: run the `fetch` line in [1.7](#17-build-the-practice-repository) |
| `... already exists. Move earlier outputs aside` | That run number has outputs. Use `--start` with the next number, or move the old files out of `outputs/` |
| `--runs-dir must be outside the eval set` | Keep `$HOME/eval-runs` and the eval set apart, never one inside the other |
| A row starts `CREDENTIAL FOUND IN OUTPUT` | Code in the run printed the credential. The file was replaced. **Revoke the credential now** and create a new one |
| A run denies a test command | The command Claude ran doesn't match `allow` in `case.json`. Claude must use `npm --prefix web test`, not `cd web && npm test`: the read block refuses a `cd` it can't check |
| First run of a case is slow | The first setup fills the package caches; later ones take seconds. The first `run-case` also compiles the harness. On Windows, file sharing into the containers and antivirus scanning add more |
| The image build or a setup fails with a certificate or TLS error | A company proxy (such as Zscaler) is inspecting TLS. Ask your IT team for the proxy's root certificate, add it to Docker Desktop's trusted certificates, and add a `COPY` and `update-ca-certificates` step for it to `templates/eval-run.Dockerfile` |
| Windows: `Filename too long` | `git config --global core.longpaths true` |
| Tracker formulas show 0 or nothing | Choose **Enable Editing** in Excel; in other spreadsheets, recalculate |
