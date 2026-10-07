# Evaluate Claude Code on Your Own Work

**Claude Lab** from World Wide Technology. 3 hours, Intermediate.

In this workshop you decide, with evidence, which engineering tasks Claude Code is ready to take on across your organization. You turn pull requests your team already merged into evaluation cases, calibrate how they are graded, and run an isolated baseline with `claude -p`. You then make a decision for each task, with an owner.

This repository holds everything a participant needs, plus two complete practice kits on fictional codebases, so you can follow along without your own pull requests.

## Start here: choose your walkthrough

The method, the exercises, and the tracker are the same in both. Pick the one that fits your team:

| Your team | Walkthrough | Practice kit | Workbook, pre-work, and deck |
|---|---|---|---|
| Any stack, including people who have never used a terminal, git, or Python | **→ [WALKTHROUGH.md](WALKTHROUGH.md)** | [demo/python-fastapi/](demo/python-fastapi/): a FastAPI service, on macOS, Linux, or Windows with WSL | `ccw5g-…` |
| .NET and Angular engineers who already use Claude Code day to day | **→ [WALKTHROUGH-dotnet.md](WALKTHROUGH-dotnet.md)** | [demo/dotnet-angular/](demo/dotnet-angular/): an ASP.NET Core and Angular app, on Windows, WSL, macOS, or Linux, with every run in its own container | `ccw5gd-…` |

Each walkthrough has two tracks:

| Track | Use it when | What you work on |
|---|---|---|
| **A. Practice** | Before the session, to rehearse; during it, if you have no suitable pull requests; or self-paced, with no presenter | The kit's fictional service and six replayable practice cases, with an answer key |
| **B. Your own repositories** | In a live session with your team | Your merged pull requests, prepared with the pre-work |

## What's in this repository

| Path | What it is |
|---|---|
| [WALKTHROUGH.md](WALKTHROUGH.md) | Setup, then every segment and exercise, step by step, for the Python kit and for your own repositories. Written for people new to terminals |
| [WALKTHROUGH-dotnet.md](WALKTHROUGH-dotnet.md) | The same workshop for .NET and Angular teams, with the containerized runs |
| [ccw5g-slides.pptx](ccw5g-slides.pptx) · [ccw5gd-slides.pptx](ccw5gd-slides.pptx) | The workshop deck (26 slides), for each walkthrough |
| Participant workbook: [markdown](ccw5g-participant-workbook.md) · [Word](ccw5g-participant-workbook.docx); .NET and Angular: [markdown](ccw5gd-participant-workbook.md) · [Word](ccw5gd-participant-workbook.docx) | Exercises 1–5 with space to draft, reference pages, and a glossary. Read the markdown on GitHub; use the Word file to print or fill in |
| Pre-work: [markdown](ccw5g-pre-work.md) · [Word](ccw5g-pre-work.docx); .NET and Angular: [markdown](ccw5gd-pre-work.md) · [Word](ccw5gd-pre-work.docx) | Six steps your team completes before a live session (Track B), with examples and a checklist |
| [templates/](templates/) | Shared: `foundation-evaluation-tracker.xlsx` (the blank tracker) and `eval-run-settings.json` (the Claude settings every run uses). Python kit: `run-case.sh`, `check-setup.sh`, and `start.sh`. .NET and Angular kit: `run-case.cs` with its `run-case` and `run-case.cmd` wrappers, `check-setup.cs`, and `eval-run.Dockerfile` |
| [demo/](demo/) | The practice kits, one folder per variant: [demo/README.md](demo/README.md) lists them. Each holds a fictional service, its history and case files, and an `ANSWERS.md` |

## What you need

**For WALKTHROUGH.md, no experience with terminals, git, or Python is needed.** Its [§1](WALKTHROUGH.md#1-setup) explains how to get each of these, step by step:

| You need | Details |
|---|---|
| A computer | macOS 13 or later, Linux (Ubuntu 20.04+, Debian 10+), or Windows 10 (version 2004+) or 11 **with WSL**. About 1 GB of free disk space and an internet connection |
| git | Version 2.28 or later |
| Python | Version 3.11, 3.12, or 3.13 |
| Claude Code | Version 2.1.257 or later, signed in |
| A Claude account | A Pro, Max, Team, or Enterprise plan, a Console account, or your organization's Amazon Bedrock, Google Cloud, or Microsoft Foundry setup |
| A spreadsheet | Excel recommended. LibreOffice and Google Sheets usually work |
| A budget for model calls | Each `claude -p` run is billed to your account. In testing, one practice run cost about $0.40, so a full set of 18 runs is around $7 |

**For WALKTHROUGH-dotnet.md:** git, the .NET 10 SDK, Docker running Linux containers, about 8 GB of free disk, and a credential for the runs that you can revoke afterwards. No Python or Node is needed on your computer. Its [§1.1](WALKTHROUGH-dotnet.md#11-what-you-need) has the details. In testing, a practice run cost about $0.10.

**Not sure what you have? Run the checker for your walkthrough.** It changes nothing and tells you exactly what to install:

```bash
bash templates/check-setup.sh
dotnet run --file templates/check-setup.cs
```

## Good to know

- **Everything in `demo/` is fictional.** Northwind Freight, its people, and its results do not exist. The Northwind services *deliberately* contain weaknesses, because the practice cases and other workshops in the track use them as teaching material. Never deploy them, and don't fix them.
- **No presenter material is included.** The facilitator guide, talk track, and demo run sheet are kept by your WWT presenter.
- The markdown and Word versions of the workbooks and the pre-work are generated from one source, so they always match. Send corrections to your WWT presenter rather than editing any of these files here.
