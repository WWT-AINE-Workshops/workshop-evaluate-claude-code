# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot and others) working in this repository. `CLAUDE.md` imports this file.

## What this repository is

The participant kit for **Claude Lab: Evaluate Claude Code on Your Own Work**, from World Wide Technology. It teaches how to measure, from merged pull requests, which engineering tasks Claude Code is ready to take on. There are two step-by-step guides with the same method: [WALKTHROUGH.md](WALKTHROUGH.md), for anyone, with a Python practice kit; and [WALKTHROUGH-dotnet.md](WALKTHROUGH-dotnet.md), for .NET and Angular teams, with a containerized practice kit. [README.md](README.md) describes the layout.

## Rules

1. **Don't fix the Northwind services.** `demo/python-fastapi/northwind-shipments-api/` and `demo/dotnet-angular/northwind-dispatch-portal/` are fictional practice material with deliberately seeded weaknesses, and the practice cases depend on them. The Python service is also shared with other workshops, which depend on it being exactly as it is. Don't patch, refactor, or "improve" either, even when asked to review it. Report what you find instead.
2. **Don't edit the generated documents.** The `.docx`, `.pptx`, `.xlsx`, and the workbook and pre-work `.md` files (`ccw5g-…` and `ccw5gd-…`) are built elsewhere from one source. Fill in a *copy* of the tracker, kept in the participant's `eval-set` folder, never `templates/foundation-evaluation-tracker.xlsx` itself.
3. **Keep evaluation runs out of this repository.** Practice runs happen in a separate runs folder (`~/nw-runs` for the Python kit, `~/eval-runs` for the .NET kit). Never in this repository, and never inside an `eval-set` folder. The `eval-set` folders and the full-history practice repositories (`~/nw-foundation/northwind-shipments-api`, `~/nwd-foundation/northwind-dispatch-portal`) contain the answers.
4. **When helping with an exercise, don't read ahead.** `demo/*/ANSWERS.md` and `demo/*/eval-set/` are the answer keys. Open them only when the participant has finished the exercise and asks to compare.
5. **Match the walkthrough's audience.** With WALKTHROUGH.md, assume the participant is a beginner: they may never have used a terminal, git, or Python, so explain what a command does before running it for them, say what they should see, and point them to the matching step (setup is §1). With WALKTHROUGH-dotnet.md, assume an experienced engineer: be brief, and explain the reasoning behind the isolation rather than the commands.
6. **Use the commands in the walkthrough.** Every run uses a single-branch clone with no tags and no remote, `claude -p` with `--settings <eval-set>/eval-run-settings.json` and `--setting-sources project,local --strict-mcp-config --no-session-persistence` (so the participant's personal setup stays out of the runs), and cleans up afterwards. For the Python kit, `templates/run-case.sh` does it with one `git worktree add --detach` per run. For the .NET kit, `templates/run-case.cs` does it with one clone and one set of Docker containers per run, reading each case's `case.json`.
7. **Never handle a participant's run credential.** Don't ask for it, print it, or put it in a file other than the one the walkthrough names. If a run's output shows one, tell the participant to revoke it.

## Useful commands

```bash
# Python kit
bash templates/check-setup.sh                                                # check the computer, and say how to fix what's missing
source templates/start.sh                                                   # set up a new terminal window (KIT, PATH, PYTHON, the venv)
./demo/python-fastapi/make-foundation-history.sh --verify ~/nw-foundation   # build the practice repository and case files, and check them
templates/run-case.sh --help                                                # run one case N times in isolated worktrees

# .NET and Angular kit
dotnet run --file templates/check-setup.cs -- --live                        # check the computer, Docker, and that a run container can sign in
templates/run-case --help                                                   # run one case N times, one container per run (run-case.cmd on Windows)
```
