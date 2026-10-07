# demo/python-fastapi/: the Northwind practice kit

Everything here is **fictional**: Northwind Freight, its people, its pull requests, and its results don't exist. The kit lets you work through the whole workshop on a small, realistic codebase before, or instead of, using your own.

**Follow [WALKTHROUGH.md](../../WALKTHROUGH.md).** This page only says what each item is. [demo/README.md](../README.md) lists the other practice variants.

| Item | What it is |
|---|---|
| `make-foundation-history.sh` | Builds the practice repository and its case files. Run it once: `./make-foundation-history.sh --verify ~/nw-foundation` (see the walkthrough, step 1.13) |
| `northwind-shipments-api/` | The fictional service (FastAPI, SQLite, pytest) that the script starts from. **Don't run cases here, and don't edit it.** The script copies it |
| `eval-set/P-01` … `P-06/` | A read-only copy of the six practice cases the script writes to `~/nw-foundation/eval-set/`, for browsing on GitHub. This is the answer key for Exercise 2, so look after you've written your own cases |
| `ANSWERS.md` | The answer key for Exercises 1–5. Open each section only after the exercise |

## The six practice cases

| Case | Target task | Pull request | What makes it interesting |
|---|---|---|---|
| P-01 | Bug fix from a closed issue | #151 | The weak attempt (#149) "fixed" the 500 by editing a test |
| P-02 | Bug fix from a closed issue | #158 | The tests can't tell a right fix from a wrong one: only the diff can |
| P-03 | Unit tests for changed code | #153 | Tests for working code: the reviewer checks the conventions |
| P-04 | Unit tests for changed code | #163 | Good tests fail on the bug. The weak attempt (#161) asserted it |
| P-05 | Pull request review | #170 (open) | One real finding to catch, among nothing worth commenting on |
| P-06 | Pull request review | #170 and #171 (open) | "Review this": the right answer is a question |

## Two warnings

- **The service contains deliberate security weaknesses.** Other workshops in the track use them as teaching material, and the practice history fixes only two of them, in pull requests 158 and 163. Never deploy it, and don't fix the copy in this folder.
- **`~/nw-foundation` holds the answers.** It has the full history and the reference outputs. Claude only ever runs in `~/nw-runs`, with the eval-run settings file (`templates/eval-run-settings.json`, which the script also copies into `~/nw-foundation/eval-set/`). The walkthrough explains why.
