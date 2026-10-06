# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot and others) working in this repository. `CLAUDE.md` imports this file.

## What this repository is

The participant kit for **Claude Lab: Evaluate Claude Code on Your Own Work**, from World Wide Technology. It teaches how to measure, from merged pull requests, which engineering tasks Claude Code is ready to take on. [WALKTHROUGH.md](WALKTHROUGH.md) is the step-by-step guide. [README.md](README.md) describes the layout.

## Rules

1. **Don't fix the Northwind service.** `demo/northwind-shipments-api/` is fictional practice material with deliberately seeded security weaknesses and one safe decoy. Other workshops depend on it being exactly as it is. Don't patch it, refactor it, or "improve" it, even when asked to review it. Report what you find instead.
2. **Don't edit the generated documents.** The `.docx`, `.pptx`, `.xlsx`, and the workbook and pre-work `.md` files (`ccw5g-participant-workbook.md`, `ccw5g-pre-work.md`) are built elsewhere from one source. Fill in a *copy* of the tracker, kept in the participant's `eval-set` folder, never `templates/foundation-evaluation-tracker.xlsx` itself.
3. **Keep evaluation runs out of this repository.** Practice runs happen in a separate runs folder, such as `~/nw-runs`, created by the walkthrough. Never in this repository, and never inside an `eval-set` folder. The `eval-set` folder and the full-history practice repository (`~/nw-foundation/northwind-shipments-api`) contain the answers.
4. **When helping with an exercise, don't read ahead.** `demo/ANSWERS.md` and `demo/eval-set/` are the answer key. Open them only when the participant has finished the exercise and asks to compare.
5. **Assume the participant is a beginner.** They may never have used a terminal, git, or Python. Explain what a command does before running it for them, say what they should see, and point them to the matching step in [WALKTHROUGH.md](WALKTHROUGH.md) (setup is §1) rather than improvising.
6. **Use the commands in the walkthrough.** Isolated runs use a single-branch clone with no tags, one `git worktree add --detach` per run, `claude -p` with `--settings <eval-set>/eval-run-settings.json`, and `git worktree remove --force` afterwards. `templates/run-case.sh` does all of it.

## Useful commands

```bash
bash templates/check-setup.sh                                 # check the computer, and say how to fix what's missing
source templates/start.sh                                    # set up a new terminal window (KIT, PATH, PYTHON, the venv)
./demo/make-foundation-history.sh --verify ~/nw-foundation   # build the practice repository and case files, and check them
templates/run-case.sh --help                                 # run one case N times in isolated worktrees
```
