#!/usr/bin/env bash
# Runs one eval case several times, each in a fresh git worktree, and prints one row per run for the
# tracker's Runs tab (columns A to M, tab-separated, ready to paste). A person still grades every run.
#
# Examples, with the Northwind demo built by make-foundation-history.sh ~/nw-foundation
# (each case's context.md in the eval set has its full command). N=~/nw-foundation/northwind-shipments-api
#   Bug fix (P-01, P-02): copy the merged pull request's tests in, then run the suite.
#     run-case.sh --case P-01 --repo $N --branch case/P-01 --request ~/nw-foundation/eval-set/P-01/request.md \
#       --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
#       --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
#       --reference-repo $N --reference-ref pr-151-merged --reference-files tests/test_shipments.py
#   Tests for unchanged code (P-03): run the suite on Claude's tree, nothing copied in.
#     run-case.sh --case P-03 --repo $N --branch case/P-03 --request ~/nw-foundation/eval-set/P-03/request.md \
#       --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
#       --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs
#   Tests that must catch a bug (P-04): run Claude's tests before and after copying in the fixed code.
#     run-case.sh --case P-04 --repo $N --branch case/P-04 --request ~/nw-foundation/eval-set/P-04/request.md \
#       --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
#       --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
#       --reference-repo $N --reference-ref pr-163-merged --reference-files app/routes/admin.py --check-before
#   Review (P-05, P-06): no --test; read-only git; grade the reply. P-06 also needs the open pull requests' branches.
#     run-case.sh --case P-06 --repo $N --branch case/P-06 --request ~/nw-foundation/eval-set/P-06/request.md \
#       --allow "Bash(git log *),Bash(git show *),Bash(git diff *),Bash(git branch *)" \
#       --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs --extra-branches "pr-170 pr-171"
#
# Options:
#   --case ID            case ID, used in file names and rows
#   --repo PATH|URL      repository to clone; only --branch is cloned, without tags, and origin is removed
#   --branch NAME        case branch (the commit before the fix)
#   --extra-branches "B1 B2"
#                        also copy these branches from --repo into the clone as local branches (still no tags)
#   --request FILE       the request, sent to Claude as the prompt
#   --test CMD           test command, run in each worktree after Claude finishes. Leave it out for a review
#                        case: the reply (.md) is graded by a person against note.md
#   --allow LIST         value for Claude's --allowedTools
#   --eval-set DIR       eval set folder; outputs go to DIR/outputs
#   --runs-dir DIR       where the clone and worktrees are made; must be outside the eval set and the repository
#   --runs N             number of runs, in parallel (default 3)
#   --start N            number of the first run (default 1); use --start 2 --runs 2 after doing run 1 by hand
#   --settings FILE      Claude settings for the runs (default DIR/eval-run-settings.json)
#   --reference-repo, --reference-ref, --reference-files "PATHS"
#                        copy these files (tests or code) from the merged ref into each worktree before
#                        running --test. --reference-tests is the same as --reference-files
#   --check-before       also run --test before the files are copied in, and report both results
#   --run-by ROLE        fills the "Run by (role)" column
#   --keep               keep the worktrees after the run (they are removed by default)
#
# Before you run it:
#   - Activate the repository's virtual environment first so the test command works.
#   - The settings file blocks Claude's reads outside the run folder
#     (permissions.blockReadsOutsideWorkingDirectories, Claude Code v2.1.257 or later) and denies web access and git push.
#   - CLAUDE_BIN overrides the claude binary (used to test this script with a stub).
set -euo pipefail

die() { echo "run-case.sh: $*" >&2; exit 1; }
# The usage text is the comment block at the top of this file.
usage() { awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0" >&2; exit 2; }
# Absolute path with symlinks resolved, also for folders that do not exist yet.
abspath() { python3 -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$1"; }
# inside CHILD PARENT: true if CHILD is PARENT or below it.
inside() { case "$1/" in "$2"/*) return 0 ;; *) return 1 ;; esac; }
g() { git -c core.hooksPath=/dev/null -c commit.gpgsign=false "$@"; }

CASE="" REPO="" BRANCH="" REQUEST="" TEST="" ALLOW="" EVALSET="" RUNSDIR="" RUNS=3 START=1 SETTINGS=""
REFREPO="" REFREF="" REFFILES="" RUNBY="" KEEP=0 CHECKBEFORE=0 EXTRA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --case) CASE="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --request) REQUEST="${2:-}"; shift 2 ;;
    --test) TEST="${2:-}"; shift 2 ;;
    --allow) ALLOW="${2:-}"; shift 2 ;;
    --eval-set) EVALSET="${2:-}"; shift 2 ;;
    --runs-dir) RUNSDIR="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-}"; shift 2 ;;
    --start) START="${2:-}"; shift 2 ;;
    --settings) SETTINGS="${2:-}"; shift 2 ;;
    --reference-repo) REFREPO="${2:-}"; shift 2 ;;
    --reference-ref) REFREF="${2:-}"; shift 2 ;;
    --reference-files|--reference-tests) REFFILES="${REFFILES:+$REFFILES }${2:-}"; shift 2 ;;
    --check-before) CHECKBEFORE=1; shift ;;
    --extra-branches) EXTRA="${EXTRA:+$EXTRA }${2:-}"; shift 2 ;;
    --run-by) RUNBY="${2:-}"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -h|--help) usage ;;
    *) echo "run-case.sh: unknown option $1" >&2; usage ;;
  esac
done

# Check the inputs before anything is created.
for pair in "case:$CASE" "repo:$REPO" "branch:$BRANCH" "request:$REQUEST" "allow:$ALLOW" \
            "eval-set:$EVALSET" "runs-dir:$RUNSDIR"; do
  [ -n "${pair#*:}" ] || die "--${pair%%:*} is required (run with --help for usage)"
done
case "$RUNS" in ''|*[!0-9]*|0) die "--runs must be a positive number" ;; esac
case "$START" in ''|*[!0-9]*|0) die "--start must be a positive number" ;; esac
LAST=$((START + RUNS - 1))
if [ -n "$REFREPO$REFREF$REFFILES" ] && { [ -z "$REFREPO" ] || [ -z "$REFREF" ] || [ -z "$REFFILES" ]; }; then
  die "--reference-repo, --reference-ref and --reference-files go together"
fi
if [ -z "$TEST" ] && [ -n "$REFREPO" ]; then die "--reference-files needs --test"; fi
if [ "$CHECKBEFORE" = 1 ] && [ -z "$REFREPO" ]; then
  die "--check-before needs --reference-repo, --reference-ref and --reference-files"
fi
[ -f "$REQUEST" ] || die "request file not found: $REQUEST"
[ -d "$EVALSET" ] || die "eval set folder not found: $EVALSET"
EVALSET="$(abspath "$EVALSET")"
RUNSDIR="$(abspath "$RUNSDIR")"
REQUEST="$(abspath "$REQUEST")"
SETTINGS="${SETTINGS:-$EVALSET/eval-run-settings.json}"
if [ ! -f "$SETTINGS" ]; then
  die "settings file not found: $SETTINGS
  Copy templates/ccw5g/eval-run-settings.json there (make-foundation-history.sh also writes one into its eval set),
  or pass --settings <file>."
fi
SETTINGS="$(abspath "$SETTINGS")"
inside "$RUNSDIR" "$EVALSET" && die "--runs-dir must be outside the eval set ($EVALSET), so Claude cannot read the answers"
if [ -d "$REPO" ]; then
  inside "$RUNSDIR" "$(abspath "$REPO")" && die "--runs-dir must be outside the repository ($REPO)"
fi
if [ -n "$REFREPO" ]; then
  [ -d "$REFREPO" ] || die "reference repository not found: $REFREPO"
  REFREPO="$(abspath "$REFREPO")"
  inside "$RUNSDIR" "$REFREPO" && die "--runs-dir must be outside the reference repository ($REFREPO)"
  for t in $REFFILES; do
    g -C "$REFREPO" cat-file -e "$REFREF:$t" 2>/dev/null || die "$t not found at $REFREF in $REFREPO"
  done
fi
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
command -v "$CLAUDE_BIN" >/dev/null 2>&1 || die "claude not found (set CLAUDE_BIN to override)"
OUT="$EVALSET/outputs"
CLONE="$RUNSDIR/eval-$CASE"
mkdir -p "$OUT" "$RUNSDIR"
i=$START
while [ "$i" -le "$LAST" ]; do
  [ -e "$RUNSDIR/$CASE-run-$i" ] && die "$RUNSDIR/$CASE-run-$i already exists. Remove it first."
  [ -e "$OUT/$CASE-run-$i.json" ] && die "$OUT/$CASE-run-$i.json already exists. Move earlier outputs aside first."
  i=$((i + 1))
done

# One clone per case: only the case branch, no tags, no origin. Later commits (the fix) are not in it.
if [ -d "$CLONE" ]; then
  [ -z "$(g -C "$CLONE" remote)" ] || die "$CLONE exists and has a remote. Remove it first."
  echo "Using existing clone $CLONE"
else
  g clone --quiet --no-local --single-branch --branch "$BRANCH" --no-tags "$REPO" "$CLONE"
  for b in $EXTRA; do
    if ! g -C "$CLONE" fetch --quiet --no-tags origin "refs/heads/$b:refs/heads/$b"; then
      rm -rf "$CLONE"
      die "branch $b not found in $REPO"
    fi
  done
  g -C "$CLONE" remote remove origin
fi
for b in $EXTRA; do
  g -C "$CLONE" rev-parse --verify --quiet "refs/heads/$b" >/dev/null || die "$CLONE has no branch $b. Remove it first."
done

VERSION="$("$CLAUDE_BIN" --version 2>/dev/null | head -1 | sed -E 's/^[^0-9]*([0-9][0-9.]*).*/\1/')"
PROMPT="$(cat "$REQUEST")"
DATE="$(date +%Y-%m-%d)"

# Make the worktrees, then start every run in parallel.
PIDS=()
i=$START
while [ "$i" -le "$LAST" ]; do
  WT="$RUNSDIR/$CASE-run-$i"
  g -C "$CLONE" worktree add --quiet --detach "$WT"
  ( cd "$WT" && exec "$CLAUDE_BIN" -p "$PROMPT" --settings "$SETTINGS" --permission-mode acceptEdits \
      --allowedTools "$ALLOW" --output-format json \
      < /dev/null > "$OUT/$CASE-run-$i.json" 2> "$OUT/$CASE-run-$i.stderr" ) &
  PIDS[i]=$!
  i=$((i + 1))
done
echo "Started $RUNS run(s) of $CASE with Claude Code $VERSION; waiting..." >&2
EXITS=()
i=$START
while [ "$i" -le "$LAST" ]; do
  if wait "${PIDS[$i]}"; then EXITS[i]=0; else EXITS[i]=$?; fi
  [ "${EXITS[$i]}" -eq 0 ] || echo "Run $i exited with ${EXITS[$i]}; see $OUT/$CASE-run-$i.stderr" >&2
  i=$((i + 1))
done

# run_tests <worktree> <log>: runs --test there and prints "pass", or "fail (<pytest counts>; see <log>)".
run_tests() {
  if (cd "$1" && bash -c "$TEST") > "$2" 2>&1; then echo pass; return; fi
  counts="$(tail -n 1 "$2" | grep -Eo '[0-9]+ (failed|errors?)' | paste -sd ',' - | sed 's/,/, /g' || true)"
  echo "fail (${counts:+$counts; }see $(basename "$2"))"
}

HEADER="Case ID	Run number	Date	Run by (role)	Claude Code version	Model	Skill or plugin used	How isolated	Verdict	What we noticed	Output location	Cost (USD)	Duration (minutes)"
TSV="$OUT/$CASE-runs.tsv"
echo "$HEADER" > "$TSV"
i=$START
while [ "$i" -le "$LAST" ]; do
  WT="$RUNSDIR/$CASE-run-$i"
  BASE="$OUT/$CASE-run-$i"
  # What Claude changed, captured before the reference files are copied in. New files are included in the diff.
  g -C "$WT" status --short > "$BASE.status"
  NEW="$(grep -c '^??' "$BASE.status" || true)"
  g -C "$WT" add --all --intent-to-add
  g -C "$WT" diff --no-color --no-ext-diff > "$BASE.diff"
  CHANGED="$(g -C "$WT" diff --name-only | wc -l | tr -d ' ')"
  # Result text to .md; cost, duration and model(s) from the JSON.
  META="$(python3 - "$BASE.json" "$BASE.md" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    data = {}
if isinstance(data, list):  # some versions print a list of messages; use the result message
    data = next((m for m in reversed(data) if isinstance(m, dict) and m.get("type") == "result"), {})
open(sys.argv[2], "w").write(str(data.get("result", "")) + "\n")
cost = data.get("total_cost_usd")
ms = data.get("duration_ms")
models = "+".join(data.get("modelUsage") or {}) or "unknown"
print("\t".join(["" if cost is None else "%.2f" % cost, "" if ms is None else "%.1f" % (ms / 60000), models]))
PY
)"
  COST="$(printf '%s' "$META" | cut -f1)"
  MINUTES="$(printf '%s' "$META" | cut -f2)"
  MODEL="$(printf '%s' "$META" | cut -f3)"
  if [ "$CHANGED" = 1 ]; then CHANGES="1 file changed"; else CHANGES="$CHANGED files changed"; fi
  CHANGES="$CHANGES; new files: $NEW"
  if [ "${EXITS[$i]}" -ne 0 ]; then
    NOTE="Run failed: exit ${EXITS[$i]}"
  elif [ -z "$TEST" ]; then
    NOTE="Review case: grade the reply (.md) against note.md; $CHANGES"
  else
    BEFORE=""
    if [ "$CHECKBEFORE" = 1 ]; then
      BEFORE="Before overlay: $(run_tests "$WT" "$BASE.tests-before.txt")"
    fi
    for t in $REFFILES; do
      mkdir -p "$WT/$(dirname "$t")"
      g -C "$REFREPO" show "$REFREF:$t" > "$WT/$t"
    done
    AFTER="$(run_tests "$WT" "$BASE.tests.txt")"
    if [ -n "$BEFORE" ]; then NOTE="$BEFORE; after overlay: $AFTER; $CHANGES"
    elif [ -n "$REFREPO" ]; then NOTE="Reference tests: $AFTER; $CHANGES"
    else NOTE="Tests: $AFTER; $CHANGES"
    fi
  fi
  if [ "$KEEP" = 0 ]; then g -C "$CLONE" worktree remove --force "$WT"; fi
  LOCATION="$BASE"
  case "$LOCATION" in "$HOME"/*) LOCATION="~${LOCATION#"$HOME"}" ;; esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$CASE" "$i" "$DATE" "$RUNBY" "$VERSION" "$MODEL" \
    "None" "Fresh worktree" "" "$NOTE" "$LOCATION" "$COST" "$MINUTES" >> "$TSV"
  i=$((i + 1))
done
if [ "$KEEP" = 0 ]; then g -C "$CLONE" worktree prune; fi

echo
cat "$TSV"
echo
echo "Rows saved to $TSV (paste them into the Runs tab)."
if [ "$KEEP" = 1 ]; then echo "Worktrees kept in $RUNSDIR."; fi
if [ -z "$TEST" ]; then
  echo "Grade each run: read the reply (.md) against note.md, check Must include / Must not, then type the verdict in the Runs tab."
else
  echo "Grade each run: read the .diff and .status, check Must include / Must not, then type the verdict in the Runs tab."
fi
