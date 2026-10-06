# Evaluate Claude Code on Your Own Work

**Claude Lab** from World Wide Technology. 3 hours, Intermediate.

In this workshop you decide, with evidence, which engineering tasks Claude Code is ready to take on across your organization. You turn pull requests your team already merged into evaluation cases, calibrate how they are graded, and run an isolated baseline with `claude -p` in fresh worktrees. You then make a decision for each task, with an owner.

This repository holds everything a participant needs, plus a complete practice track on a fictional codebase, so you can follow along without your own pull requests.

## Start here

**→ [WALKTHROUGH.md](WALKTHROUGH.md)** gives the full step-by-step guide, in the order of the workshop agenda.

The walkthrough has two tracks:

| Track | Use it when | What you work on |
|---|---|---|
| **A. Practice on Northwind** | Before the session, to rehearse; during it, if you have no suitable pull requests; or self-paced, with no presenter | The fictional `northwind-shipments-api` and six replayable practice cases, with an answer key |
| **B. Your own repositories** | In a live session with your team | Your merged pull requests, prepared with the pre-work ([markdown](ccw5g-pre-work.md) · [Word](ccw5g-pre-work.docx)) |

## What's in this repository

| Path | What it is |
|---|---|
| [WALKTHROUGH.md](WALKTHROUGH.md) | Setup, then every segment and exercise, step by step, for both tracks |
| [ccw5g-slides.pptx](ccw5g-slides.pptx) | The workshop deck (26 slides) |
| Participant workbook: [markdown](ccw5g-participant-workbook.md) · [Word](ccw5g-participant-workbook.docx) | Exercises 1–5 with space to draft, reference pages, and a glossary. Read the markdown on GitHub; use the Word file to print or fill in |
| Pre-work: [markdown](ccw5g-pre-work.md) · [Word](ccw5g-pre-work.docx) | Six steps your team completes before a live session (Track B), with examples and a checklist. Read the markdown on GitHub; use the Word file to share or print |
| [templates/](templates/) | `foundation-evaluation-tracker.xlsx` (the blank tracker), `eval-run-settings.json` (stops Claude reading outside the run folder), `run-case.sh` (runs one case three times in isolated worktrees), `check-setup.sh` (checks your computer and says how to fix what's missing), and `start.sh` (sets up each new terminal window) |
| [demo/](demo/) | The Northwind practice kit: the fictional service, the script that builds its history and case files, and [ANSWERS.md](demo/ANSWERS.md) |

## What you need

**No experience with terminals, git, or Python is needed.** [WALKTHROUGH.md §1](WALKTHROUGH.md#1-setup) explains how to get each of these, step by step, on macOS, Linux, and Windows:

| You need | Details |
|---|---|
| A computer | macOS 13 or later, Linux (Ubuntu 20.04+, Debian 10+), or Windows 10 (version 2004+) or 11 **with WSL**. About 1 GB of free disk space and an internet connection |
| A terminal | Built into your computer. On Windows, set up WSL first |
| git | Version 2.28 or later |
| Python | Version 3.11, 3.12, or 3.13 |
| Claude Code | Version 2.1.257 or later, signed in |
| A Claude account | A Pro, Max, Team, or Enterprise plan, a Console account, or your organization's Amazon Bedrock, Google Cloud, or Microsoft Foundry setup |
| A spreadsheet | Excel recommended. LibreOffice and Google Sheets usually work |
| A budget for model calls | Each `claude -p` run is billed to your account. In testing, one practice run cost about $0.40, so a full set of 18 runs is around $7. Every run's JSON output reports its exact cost |

**Not sure what you have? Run the checker.** It looks at your computer, changes nothing, and tells you exactly what to install and how:

```bash
bash templates/check-setup.sh
```

## Good to know

- **Everything in `demo/` is fictional.** Northwind Freight, its people, and its results do not exist. The Northwind service *deliberately* contains security weaknesses, because other workshops in the track use them as teaching material. Never deploy it, and don't fix it.
- **No presenter material is included.** The facilitator guide, talk track, and demo run sheet are kept by your WWT presenter.
- The markdown and Word versions of the workbook and the pre-work are generated from one source, so they always match. Send corrections to your WWT presenter rather than editing any of these files here.
