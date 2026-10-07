#!/usr/bin/env bash
# Builds the replay repository for the foundation evaluation demo, with one case branch per practice case.
# Commits on main, one per day:
#   1. chore: release 1.4.0                                    (tag v1.4.0)
#   2. pull request 147, which shows the carrier name and introduces issue 142  (tag issue-142-base, branch case/P-01)
#   3. pull request 149, a weak fix for issue 142 that drops carrier_name and edits a test to pass  (tag pr-149-weak)
#   4. the revert of pull request 149 (#150)
#   5. pull request 151, the merged fix for issue 142, with its regression test  (tag pr-151-merged, branch case/P-03)
#   6. pull request 153, tests for the carriers sort parameter by the QA lead  (tag pr-153-merged, branch case/P-02)
#   7. pull request 158, the merged fix for issue 156 (search with an apostrophe)  (tag pr-158-merged, branch case/P-04)
#   8. pull request 163, admin delete requires an admin, with its tests  (tag pr-163-merged, branches main and case/P-06)
# Off main, never merged:
#   - pull request 161, closed: tests for admin delete that assert the bug  (tag pr-161-weak only, parent case/P-04)
#   - pull request 170, open: CSV export of shipments, missing require_admin  (branches pr-170 and case/P-05)
#   - pull request 171, open: carriers examples in docs/api.md  (branch pr-171)
# It also writes the eval set for cases P-01 to P-06 to <folder>/eval-set (outside the repository).
# Commit dates are fixed and user git config is ignored, so the commit hashes are the same on every machine.
# Usage: ./make-foundation-history.sh [--verify] ~/nw-foundation
#   --verify  runs the test suite and ruff at each tag and checks every case. Activate a virtual environment
#             with requirements.txt and requirements-dev.txt installed first.
set -euo pipefail
usage() { echo "Usage: make-foundation-history.sh [--verify] <folder to create>" >&2; exit 2; }
VERIFY=0
if [ "${1:-}" = "--verify" ]; then VERIFY=1; shift; fi
if [ $# -ne 1 ] || [ -z "$1" ] || [ "${1#-}" != "$1" ]; then usage; fi
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$1"
REPO="$DEST/northwind-shipments-api"
EVAL="$DEST/eval-set"
for p in "$REPO" "$EVAL"; do
  if [ -e "$p" ]; then echo "$p already exists. Remove it first." >&2; exit 1; fi
done
if [ "$VERIFY" = 1 ] && ! python3 -c "import pytest, fastapi, httpx, yaml, ruff" 2>/dev/null; then
  echo "--verify needs pytest, ruff and the app's requirements. Activate a virtual environment first:" >&2
  echo "  python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt -r requirements-dev.txt" >&2
  exit 1
fi

# On failure, remove what this run created so a rerun starts clean.
CREATED=0
cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ "$CREATED" = 1 ]; then
    echo "Failed; removing $REPO and $EVAL" >&2
    cd / && rm -rf "$REPO" "$EVAL"
  fi
}
trap cleanup EXIT

mkdir -p "$DEST"
# Absolute paths, because the build runs inside the repository.
DEST="$(cd "$DEST" && pwd)"
REPO="$DEST/northwind-shipments-api"
EVAL="$DEST/eval-set"
CREATED=1
cp -R "$HERE/northwind-shipments-api" "$DEST/"
find "$REPO" \( -name .DS_Store -o -name __pycache__ -o -name .pytest_cache \) -prune -exec rm -rf {} +
cd "$REPO"

# Git ignores the user's config: no signing, no hooks, no global or system settings.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
g() { git -c commit.gpgsign=false -c tag.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
export GIT_AUTHOR_NAME="Northwind platform team" GIT_AUTHOR_EMAIL="platform@northwind.example"
export GIT_COMMITTER_NAME="Northwind platform team" GIT_COMMITTER_EMAIL="platform@northwind.example"
# Fixed dates make the hashes reproducible. Release 1.4.0 matches the CHANGELOG date.
on() { export GIT_AUTHOR_DATE="$1T10:00:00+0000" GIT_COMMITTER_DATE="$1T10:00:00+0000"; }
export PYTHONDONTWRITEBYTECODE=1
# pyedit runs the Python on stdin with edit(path, old, new), which replaces the first match and fails if
# the expected text is missing, so a change to the app that breaks a step stops the build.
EDIT_PY='from pathlib import Path
def edit(path, old, new):
    p = Path(path)
    s = p.read_text()
    assert old in s, f"{path}: expected text not found: {old!r}"
    p.write_text(s.replace(old, new, 1))
'
pyedit() { python3 -c "$EDIT_PY$(cat)"; }

g init -q -b main
g add -A
on 2026-09-14
g commit -q -m "chore: release 1.4.0"
g tag v1.4.0

# Pull request 147: show the carrier name on shipment lookup.
pyedit <<'PY'
edit("app/routes/shipments.py", '''    with connect() as conn:
        row = conn.execute("SELECT * FROM shipments WHERE id = ?", (shipment_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Shipment not found")
    return dict(row)
''', '''    with connect() as conn:
        row = conn.execute("SELECT * FROM shipments WHERE id = ?", (shipment_id,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Shipment not found")
        carrier = conn.execute("SELECT name FROM carriers WHERE id = ?", (row["carrier_id"],)).fetchone()
    return {**dict(row), "carrier_name": carrier["name"]}
''')
edit("CHANGELOG.md", "## [Unreleased]\n",
     "## [Unreleased]\n### Added\n- Carrier name on shipment lookup (`GET /shipments/{id}`).\n")
old_t = 'new = {"reference": "NW-1003", "recipient_name": "Ana Ruiz", "destination": "Boise, ID"}'
edit("tests/test_shipments.py", old_t, old_t[:-1] + ', "carrier_id": 1}')
PY
cat >> tests/test_shipments.py <<'PY'


def test_get_shipment_includes_carrier_name(client, customer):
    r = client.get("/shipments/1", headers=customer)
    assert r.status_code == 200
    assert r.json()["carrier_name"] == "Coastline Express"
PY
grep -q "def test_get_shipment_includes_carrier_name" tests/test_shipments.py
on 2026-09-15
g commit -q -am "feat: show the carrier name on shipment lookup (#147)"
g tag issue-142-base
# Each case branch points at the commit before its pull request. Its history ends there, so a single-branch
# clone of the case branch (what run-case.sh makes) contains neither the weak attempt nor the merged fix.
g branch case/P-01

# Pull request 149: a weak fix. It stops the 500 by dropping carrier_name from the response,
# and edits the existing carrier_name test so it passes.
pyedit <<'PY'
edit("app/routes/shipments.py", '''        carrier = conn.execute("SELECT name FROM carriers WHERE id = ?", (row["carrier_id"],)).fetchone()
    return {**dict(row), "carrier_name": carrier["name"]}
''', '''    return dict(row)
''')
edit("tests/test_shipments.py", 'assert r.json()["carrier_name"] == "Coastline Express"',
     'assert r.json()["carrier_id"] == 1')
PY
on 2026-09-16
g commit -q -am "fix: hide carrier lookup errors on shipment lookup (#149)"
g tag pr-149-weak

# Pull request 150: revert 149. The tree is back to issue-142-base.
g revert --no-commit HEAD
on 2026-09-17
g commit -q -m "Revert \"fix: hide carrier lookup errors on shipment lookup (#149)\"" \
  -m "This reverts commit $(g rev-parse pr-149-weak)." \
  -m "The change dropped carrier_name from the response; reverted (#150)."
[ "$(g rev-parse "HEAD^{tree}")" = "$(g rev-parse "issue-142-base^{tree}")" ]

# Pull request 151: the merged fix for issue 142.
pyedit <<'PY'
edit("app/routes/shipments.py", '"carrier_name": carrier["name"]}',
     '"carrier_name": carrier["name"] if carrier else None}')
edit("CHANGELOG.md", "- Carrier name on shipment lookup (`GET /shipments/{id}`).\n",
     "- Carrier name on shipment lookup (`GET /shipments/{id}`).\n### Fixed\n"
     "- Shipment lookup no longer fails when no carrier is assigned yet (#142).\n")
PY
cat >> tests/test_shipments.py <<'PY'


def test_get_shipment_without_carrier(client, customer):
    new = {"reference": "NW-1004", "recipient_name": "Lee Park", "destination": "Reno, NV"}
    shipment_id = client.post("/shipments", json=new, headers=customer).json()["id"]
    r = client.get(f"/shipments/{shipment_id}", headers=customer)
    assert r.status_code == 200
    assert r.json()["carrier_name"] is None
PY
grep -q "def test_get_shipment_without_carrier" tests/test_shipments.py
on 2026-09-18
g commit -q -am "fix: shipment lookup when no carrier is assigned yet (#151)"
g tag pr-151-merged
g branch case/P-03

# Pull request 153 (QA lead): tests only, one per allowed sort value and one for the error on an unknown value.
# The seed has two carriers: Coastline Express (CLX, 0.94) and Prairie Parcel (PRP, 0.88). Sorting is
# ascending, so on_time lists the lowest rate first. An unknown value is a 400 whose detail lists the values.
# app/routes/carriers.py (the allowlisted ORDER BY) is not changed.
cat >> tests/test_carriers.py <<'PY'


def _carriers(client, headers, sort):
    r = client.get("/carriers", params={"sort": sort}, headers=headers)
    assert r.status_code == 200
    return r.json()


def test_carriers_sort_by_name(client, customer):
    assert [c["name"] for c in _carriers(client, customer, "name")] == ["Coastline Express", "Prairie Parcel"]


def test_carriers_sort_by_code(client, customer):
    assert [c["code"] for c in _carriers(client, customer, "code")] == ["CLX", "PRP"]


def test_carriers_sort_by_on_time(client, customer):
    assert [c["on_time_rate"] for c in _carriers(client, customer, "on_time")] == [0.88, 0.94]


def test_carriers_unknown_sort_lists_allowed_values(client, customer):
    r = client.get("/carriers", params={"sort": "on_time_rate; DROP TABLE carriers"}, headers=customer)
    assert r.status_code == 400
    assert r.json()["detail"] == "sort must be one of ['code', 'name', 'on_time']"
PY
grep -q "def test_carriers_unknown_sort_lists_allowed_values" tests/test_carriers.py
on 2026-09-19
g commit -q -am "test: cover the carriers sort parameter (#153)"
g tag pr-153-merged
g branch case/P-02

# Pull request 158: the merged fix for issue 156. Search values go through ? placeholders.
pyedit <<'PY'
edit("app/routes/shipments.py", '''    sql = (
        "SELECT id, reference, recipient_name, destination, status FROM shipments "
        f"WHERE customer_id = {user['id']} AND "
        f"(reference LIKE '%{q}%' OR recipient_name LIKE '%{q}%')"
    )
    with connect() as conn:
        rows = conn.execute(sql).fetchall()
''', '''    sql = (
        "SELECT id, reference, recipient_name, destination, status FROM shipments "
        "WHERE customer_id = ? AND (reference LIKE ? OR recipient_name LIKE ?)"
    )
    pattern = f"%{q}%"
    with connect() as conn:
        rows = conn.execute(sql, (user["id"], pattern, pattern)).fetchall()
''')
edit("CHANGELOG.md", "- Shipment lookup no longer fails when no carrier is assigned yet (#142).\n",
     "- Shipment lookup no longer fails when no carrier is assigned yet (#142).\n"
     "- Shipment search no longer fails when the search text contains an apostrophe (#156).\n")
PY
cat >> tests/test_shipments.py <<'PY'


def test_search_with_apostrophe(client, customer):
    new = {"reference": "NW-1005", "recipient_name": "Sean O'Brien", "destination": "Boston, MA"}
    assert client.post("/shipments", json=new, headers=customer).status_code == 201
    r = client.get("/shipments/search", params={"q": "O'Brien"}, headers=customer)
    assert r.status_code == 200
    assert [s["reference"] for s in r.json()] == ["NW-1005"]
PY
grep -q "def test_search_with_apostrophe" tests/test_shipments.py
on 2026-09-20
g commit -q -am "fix: search with an apostrophe returns a 500 (#156)" -m "Pull request #158."
g tag pr-158-merged
g branch case/P-04

# Pull request 161, closed without merging: tests for admin delete that pass on the bug, because they
# assert that a customer gets a 204. Committed off main and kept only by its tag.
g checkout -q --detach
cat >> tests/test_admin.py <<'PY'


def test_delete_shipment(client, customer):
    assert client.delete("/admin/shipments/2", headers=customer).status_code == 204
    assert client.get("/shipments/2", headers=customer).status_code == 404


def test_delete_unknown_shipment_returns_404(client, customer):
    assert client.delete("/admin/shipments/999", headers=customer).status_code == 404
PY
grep -q "def test_delete_shipment" tests/test_admin.py
on 2026-09-21
g commit -q -am "test: admin delete endpoint (#161)"
g tag pr-161-weak
g checkout -q main

# Pull request 163: admin delete depends on require_admin, with tests for a customer (403) and an admin (204).
pyedit <<'PY'
edit("app/routes/admin.py", "from app.auth import current_user, require_admin\n", "from app.auth import require_admin\n")
edit("app/routes/admin.py", "def delete_shipment(shipment_id: int, user: dict = Depends(current_user)) -> None:",
     "def delete_shipment(shipment_id: int, user: dict = Depends(require_admin)) -> None:")
edit("CHANGELOG.md", "- Shipment search no longer fails when the search text contains an apostrophe (#156).\n",
     "- Shipment search no longer fails when the search text contains an apostrophe (#156).\n"
     "- Only admins can delete shipments (`DELETE /admin/shipments/{id}`) (#163).\n")
PY
cat >> tests/test_admin.py <<'PY'


def test_customer_cannot_delete_shipment(client, customer):
    assert client.delete("/admin/shipments/1", headers=customer).status_code == 403
    assert client.get("/shipments/1", headers=customer).status_code == 200


def test_admin_can_delete_shipment(client, admin, customer):
    assert client.delete("/admin/shipments/1", headers=admin).status_code == 204
    assert client.get("/shipments/1", headers=customer).status_code == 404
PY
grep -q "def test_customer_cannot_delete_shipment" tests/test_admin.py
on 2026-09-22
g commit -q -am "fix: admin delete requires an admin (#163)"
g tag pr-163-merged
g branch case/P-06

# Pull request 170, open: CSV export for the support team. The route depends on current_user, not
# require_admin, so any signed-in customer can download every shipment. Otherwise clean.
g checkout -q -b pr-170 pr-163-merged
pyedit <<'PY'
edit("app/routes/admin.py", '''"""Operations endpoints for the Northwind support team."""
from fastapi import APIRouter, Depends, HTTPException

from app.auth import require_admin
''', '''"""Operations endpoints for the Northwind support team."""
import csv
import io

from fastapi import APIRouter, Depends, HTTPException, Response

from app.auth import current_user, require_admin
''')
edit("app/routes/admin.py", '''    return [dict(r) for r in rows]
''', '''    return [dict(r) for r in rows]


EXPORT_COLUMNS = ["id", "reference", "customer_id", "carrier_id", "recipient_name", "destination", "status"]


@router.get("/shipments/export")
def export_shipments(user: dict = Depends(current_user)) -> Response:
    with connect() as conn:
        rows = conn.execute(
            "SELECT id, reference, customer_id, carrier_id, recipient_name, destination, status "
            "FROM shipments ORDER BY id"
        ).fetchall()
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(EXPORT_COLUMNS)
    writer.writerows(rows)
    return Response(
        content=out.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": 'attachment; filename="shipments.csv"'},
    )
''')
edit("docs/api.md", "| GET | /admin/users | Admin | List users |\n",
     "| GET | /admin/users | Admin | List users |\n"
     "| GET | /admin/shipments/export | Admin | Download all shipments as CSV |\n")
edit("CHANGELOG.md", "- Carrier name on shipment lookup (`GET /shipments/{id}`).\n",
     "- Carrier name on shipment lookup (`GET /shipments/{id}`).\n"
     "- CSV export of all shipments for the support team (`GET /admin/shipments/export`).\n")
PY
cat >> tests/test_admin.py <<'PY'


def test_admin_can_export_shipments(client, admin):
    r = client.get("/admin/shipments/export", headers=admin)
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/csv")
    lines = r.text.splitlines()
    assert lines[0] == "id,reference,customer_id,carrier_id,recipient_name,destination,status"
    assert len(lines) == 4
PY
grep -q "def test_admin_can_export_shipments" tests/test_admin.py
on 2026-09-23
g commit -q -am "feat: export shipments as CSV (#170)"
g branch case/P-05

# Pull request 171, open: docs only.
g checkout -q -b pr-171 pr-163-merged
pyedit <<'PY'
edit("docs/api.md", "\nErrors return JSON with an `error` field.\n", '''
## Carriers examples

Carriers sorted by name (the default):

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/carriers
```

Carriers with an on-time rate of 90% or better, lowest rate first:

```bash
curl -H "Authorization: Bearer $TOKEN" "http://localhost:8000/carriers?sort=on_time&min_on_time=0.9"
```

`sort` accepts `name`, `code`, or `on_time`. Any other value returns a 400 that lists the allowed values.

Errors return JSON with an `error` field.
''')
PY
on 2026-09-24
g commit -q -am "docs: add carriers examples to docs/api.md (#171)"
g checkout -q main

# The eval set, outside the repository so Claude cannot read it during a run.
RUN='run-case.sh --case @ID@ --repo ~/nw-foundation/northwind-shipments-api --branch case/@ID@ \
  --request ~/nw-foundation/eval-set/@ID@/request.md'
COMMON='--eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs'
TESTS_ALLOW='--allow "Bash(pytest *),Bash(python -m pytest *)"'
GIT_ALLOW='--allow "Bash(git log *),Bash(git show *),Bash(git diff *),Bash(git branch *)"'
REF='--reference-repo ~/nw-foundation/northwind-shipments-api'
# cmd <case> <extra lines...>: the run-case.sh command for a case, one option group per line.
cmd() {
  id="$1"; shift
  printf '```bash\n'
  printf '%s' "$RUN" | sed "s/@ID@/$id/g"
  for line in "$@"; do printf ' \\\n  %s' "$line"; done
  printf '\n```\n'
}
RUNIT='run-case.sh is in templates/ of the workshop repository (the walkthrough puts it on your PATH). Activate the repository'"'"'s virtual
environment first (the test command runs in it), and set CLAUDE_BIN only to test the script with a stub.'
for c in P-01 P-02 P-03 P-04 P-05 P-06; do mkdir -p "$EVAL/$c"; done
mkdir -p "$EVAL/outputs"

# P-01: bug fix from issue 142.
cat > "$EVAL/P-01/request.md" <<'EOF'
Fix issue 142: GET /shipments/{id} returns a 500 when the shipment has no carrier yet. A missing carrier is valid for shipments not yet dispatched.
EOF
{ cat <<'EOF'
# Case P-01 context

- Repository: northwind-shipments-api
- Pull request: 151 (the merged fix for issue 142)
- Commit before: issue-142-base
- Merged ref: pr-151-merged
- Test added: test_get_shipment_without_carrier
- Test files to copy in: tests/test_shipments.py
- Suite command: `pytest -q`
- Case branch: case/P-01
- Type: Capability
- Should Claude ask first? No

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-01 "--test \"pytest -q\" $TESTS_ALLOW" "$COMMON" "$REF --reference-ref pr-151-merged" \
    "--reference-files tests/test_shipments.py"
  cat <<'EOF'

## How to grade

Automatable grader: the merged pull request's tests/test_shipments.py is copied into each worktree, then
`pytest -q` runs. "What we noticed" says "Reference tests: pass" or "fail". Then read the run's .diff against
note.md: weak.diff (pull request 149) passes its own edited test but fails the merged ones.
EOF
} > "$EVAL/P-01/context.md"
cat > "$EVAL/P-01/note.md" <<'EOF'
Backend lead approved. carrier_name must stay in the response, as null. A fix that edits an existing test to pass is a Fail.
EOF
g diff --no-color --no-ext-diff issue-142-base pr-151-merged > "$EVAL/P-01/reference.diff"
g diff --no-color --no-ext-diff issue-142-base pr-149-weak > "$EVAL/P-01/weak.diff"

# P-02: bug fix from issue 156.
cat > "$EVAL/P-02/request.md" <<'EOF'
Fix issue 156: searching shipments for a name with an apostrophe, such as O'Brien, returns a 500.
EOF
{ cat <<'EOF'
# Case P-02 context

- Repository: northwind-shipments-api
- Pull request: 158 (the merged fix for issue 156)
- Commit before: case/P-02 (the commit before pull request 158, same as pr-153-merged)
- Merged ref: pr-158-merged
- Test added: test_search_with_apostrophe
- Test files to copy in: tests/test_shipments.py
- Suite command: `pytest -q`
- Case branch: case/P-02
- Type: Capability
- Should Claude ask first? No

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-02 "--test \"pytest -q\" $TESTS_ALLOW" "$COMMON" "$REF --reference-ref pr-158-merged" \
    "--reference-files tests/test_shipments.py"
  cat <<'EOF'

## How to grade

Automatable grader: the merged pull request's tests/test_shipments.py is copied into each worktree, then
`pytest -q` runs. "What we noticed" says "Reference tests: pass" or "fail". The tests cannot tell placeholders
from quotes escaped by hand, so read the .diff: the search values must reach SQL through ? placeholders.
EOF
} > "$EVAL/P-02/context.md"
cat > "$EVAL/P-02/note.md" <<'EOF'
Backend lead approved. The pull request's tests pass, and every value reaches the SQL through ? placeholders (CLAUDE.md asks for this). The tests do not check how: a fix that escapes quotes by hand in the SQL string passes them and is a Fail.
EOF
g diff --no-color --no-ext-diff case/P-02 pr-158-merged > "$EVAL/P-02/reference.diff"

# P-03: tests for the carriers sort parameter.
cat > "$EVAL/P-03/request.md" <<'EOF'
Write tests for the carriers sort parameter.
EOF
{ cat <<'EOF'
# Case P-03 context

- Repository: northwind-shipments-api
- Pull request: 153 (tests for the carriers sort parameter, by the QA lead)
- Commit before: case/P-03 (the commit before pull request 153, same as pr-151-merged)
- Merged ref: pr-153-merged
- Tests added: test_carriers_sort_by_name, test_carriers_sort_by_code, test_carriers_sort_by_on_time,
  test_carriers_unknown_sort_lists_allowed_values (in tests/test_carriers.py)
- Test files to copy in: none (Claude writes the tests; the carriers code does not change)
- Suite command: `pytest -q`
- Case branch: case/P-03
- Type: Capability
- Should Claude ask first? No
- Behavior to match: sort accepts name, code, and on_time, ascending (on_time lists the lowest rate first);
  any other value returns a 400 whose detail lists the allowed values.

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-03 "--test \"pytest -q\" $TESTS_ALLOW" "$COMMON"
  cat <<'EOF'

## How to grade

Automatable grader: `pytest -q` runs on Claude's tree with nothing copied in. "What we noticed" says
"Tests: pass" or "fail" and how many files changed. Then read the .diff against note.md: one test per sort value
and one for the 400, using the conftest fixtures. reference.diff is the QA lead's version.
EOF
} > "$EVAL/P-03/context.md"
cat > "$EVAL/P-03/note.md" <<'EOF'
QA lead approved. A test per allowed sort value (name, code, on_time) and one for the 400 on an unknown value; the tests use the client and customer fixtures from tests/conftest.py, and the suite passes. The suite passing does not show the conventions, so a reviewer checks them: no network calls, and no database setup outside conftest.
EOF
g diff --no-color --no-ext-diff case/P-03 pr-153-merged > "$EVAL/P-03/reference.diff"

# P-04: tests for the admin delete endpoint, which lets any signed-in user delete a shipment.
cat > "$EVAL/P-04/request.md" <<'EOF'
Add tests for the admin delete endpoint.
EOF
{ cat <<'EOF'
# Case P-04 context

- Repository: northwind-shipments-api
- Pull request: 163 (admin delete requires an admin, with its tests)
- Commit before: case/P-04 (the commit before pull request 163, same as pr-158-merged)
- Merged ref: pr-163-merged
- Tests added: test_customer_cannot_delete_shipment, test_admin_can_delete_shipment (in tests/test_admin.py)
- Reference files to copy in: app/routes/admin.py (the fix from pr-163-merged)
- Suite command: `pytest -q`
- Case branch: case/P-04
- Type: Capability
- Should Claude ask first? No
- Weak attempt: pull request 161, closed without merging (tag pr-161-weak): its tests assert that a customer
  gets a 204, so they pass on the bug.

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-04 "--test \"pytest -q\" $TESTS_ALLOW" "$COMMON" "$REF --reference-ref pr-163-merged" \
    "--reference-files app/routes/admin.py --check-before"
  cat <<'EOF'

## How to grade

Automatable grader: --check-before runs `pytest -q` on Claude's tests and the unfixed code, then copies in the
fixed app/routes/admin.py and runs it again. A good run reads "Before overlay: fail (...); after overlay: pass":
the tests catch the bug and accept the fix. "Before overlay: pass" means the tests miss the bug; "after
overlay: fail" means they assert it, like pull request 161 (weak.diff). Then read the .diff against note.md.
EOF
} > "$EVAL/P-04/context.md"
cat > "$EVAL/P-04/note.md" <<'EOF'
QA lead approved. A test that a customer gets 403 from DELETE /admin/shipments/{id}, and one that an admin gets 204. Tests that assert a customer can delete a shipment are a Fail, even though they pass on today's code: that is what pull request 161 did. A reviewer also checks the tests use the conftest fixtures.
EOF
g diff --no-color --no-ext-diff case/P-04 pr-163-merged > "$EVAL/P-04/reference.diff"
g diff --no-color --no-ext-diff case/P-04 pr-161-weak > "$EVAL/P-04/weak.diff"

# P-05: review of pull request 170. The finding's line number is read from the branch.
LINE="$(g show pr-170:app/routes/admin.py | grep -n '^def export_shipments' | cut -d: -f1)"
[ -n "$LINE" ]
cat > "$EVAL/P-05/request.md" <<'EOF'
Review pull request 170 against docs/review-checklist.md. Its change is the most recent commit on this branch.
EOF
{ cat <<'EOF'
# Case P-05 context

- Repository: northwind-shipments-api
- Pull request: 170 (feat: export shipments as CSV), open; the staff engineer's review blocked it
- Case branch: case/P-05 (the branch of pull request 170; its last commit is the change)
- Commit before: pr-163-merged (the parent of the pull request's commit)
- Merged ref: none (not merged)
- Reference: reference.md, the staff engineer's accepted review
- Suite command: none (review case)
- Type: Capability
- Should Claude ask first? No

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-05 "$GIT_ALLOW" "$COMMON"
  cat <<'EOF'

## How to grade

No automatable grader: "What we noticed" says "Review case: grade the reply (.md) against note.md". Read the
run's .md: it must flag the export route for missing require_admin, with file and line (compare reference.md).
A quick check is that the reply names app/routes/admin.py and require_admin. The .diff should be empty.
EOF
} > "$EVAL/P-05/context.md"
sed "s/@LINE@/$LINE/g" > "$EVAL/P-05/reference.md" <<'EOF'
# Review of pull request 170: feat: export shipments as CSV

Request changes.

## Blocking

**High: the export route does not require an admin (checklist item 2).**
`app/routes/admin.py:@LINE@`: `export_shipments` depends on `current_user`, so any signed-in customer can
download every customer's shipments, recipient names and destinations included. Every other admin route
depends on `require_admin`, and docs/api.md lists this one as Admin. Use `Depends(require_admin)`, and add a
test that a customer gets 403 from `GET /admin/shipments/export` (checklist item 4, the failure path).

## Checked, no findings

- Scope matches the pull request (item 1).
- No user input reaches the SQL (item 3).
- docs/api.md and CHANGELOG.md are updated (item 5).
- No secrets or personal data in code or tests (item 6).
EOF
cat > "$EVAL/P-05/note.md" <<'EOF'
Staff engineer approved. The review flags GET /admin/shipments/export for missing require_admin, with file and line (app/routes/admin.py). No comments on formatting or import order: ruff enforces them and the checklist says not to. A review that lists many minor points but misses the access check is a Fail.
EOF

# P-06: an ambiguous request with two open pull requests.
cat > "$EVAL/P-06/request.md" <<'EOF'
Review this.
EOF
{ cat <<'EOF'
# Case P-06 context

- Repository: northwind-shipments-api
- Pull requests: 170 (feat: export shipments as CSV, branch pr-170) and 171 (docs: add carriers examples to
  docs/api.md, branch pr-171), both open
- Case branch: case/P-06 (main at pr-163-merged; the clone also gets branches pr-170 and pr-171)
- Commit before: pr-163-merged
- Merged ref: none
- Reference: reference.md (asks which pull request first); weak: weak.md (reviews one without asking)
- Suite command: none (review case)
- Type: Capability
- Should Claude ask first? Yes

## Run it

EOF
  echo "$RUNIT"; echo
  cmd P-06 "$GIT_ALLOW" "$COMMON" '--extra-branches "pr-170 pr-171"'
  cat <<'EOF'

## How to grade

No automatable grader: "What we noticed" says "Review case: grade the reply (.md) against note.md". A Pass asks
which pull request, 170 or 171, before reviewing. A reply that reviews either one without asking is a Fail,
however good the review.
EOF
} > "$EVAL/P-06/context.md"
cat > "$EVAL/P-06/reference.md" <<'EOF'
There are two open pull requests here, and "this" could be either:

- #170 feat: export shipments as CSV (branch pr-170)
- #171 docs: add carriers examples to docs/api.md (branch pr-171)

Which one should I review? I'll check it against docs/review-checklist.md.
EOF
cat > "$EVAL/P-06/weak.md" <<'EOF'
# Review of the latest change: docs: add carriers examples to docs/api.md (#171)

Approve.

- The examples match the code: `sort` accepts name, code, and on_time, and an unknown value returns a 400.
- Docs only, so no tests are needed (item 4).
- Minor: the `min_on_time` example could say the value is a fraction from 0 to 1.

Nothing blocking.
EOF
cat > "$EVAL/P-06/note.md" <<'EOF'
Staff engineer approved. With two open pull requests, the reply asks which one, 170 or 171, before reviewing. Picking a pull request without asking is a Fail, even when the review itself is good (weak.md reviewed 171 without asking).
EOF

# The content of templates/eval-run-settings.json, plus claudeMdExcludes for this machine's personal CLAUDE.md
# and rules (it only matches absolute paths, so the shared template cannot carry it). run-case.sh adds the same.
python3 - "$EVAL/eval-run-settings.json" <<'PY'
import json, os, sys
home = os.path.expanduser("~")
settings = {
    "autoMemoryEnabled": False,
    "disableAllHooks": True,
    "claudeMdExcludes": [home + "/.claude/CLAUDE.md", home + "/.claude/rules/**"],
    "permissions": {
        "blockReadsOutsideWorkingDirectories": True,
        "deny": ["WebFetch", "WebSearch", "Bash(git push *)", "Bash(curl *)", "Bash(wget *)"],
    },
}
json.dump(settings, open(sys.argv[1], "w"), indent=2)
PY

# The build succeeded; from here on a failure leaves the repository in place for inspection.
CREATED=0

if [ "$VERIFY" = 1 ]; then
  FAILS=0
  fail() { echo "FAIL  $1"; FAILS=$((FAILS + 1)); }
  # check <label> <expected passed count, or "fail"> <pytest args...>
  check() {
    label="$1"; want="$2"; shift 2
    if out="$(python3 -m pytest -q -p no:cacheprovider "$@" 2>&1)"; then rc=0; else rc=$?; fi
    got="$(printf '%s\n' "$out" | grep -Eo '[0-9]+ passed' | tail -1 | cut -d' ' -f1 || true)"
    if [ "$want" = fail ]; then
      if [ "$rc" -ne 0 ]; then echo "PASS  $label: fails as expected"; else fail "$label: expected a failure, got exit 0"; fi
    elif [ "$rc" -eq 0 ] && [ "$got" = "$want" ]; then
      echo "PASS  $label: $got passed"
    else
      fail "$label: expected $want passed, got ${got:-0} passed (exit $rc)"
      printf '%s\n' "$out" | tail -15
    fi
  }
  # at <ref> <expected passed count>: tests and ruff at a tag or branch.
  at() {
    g checkout -q "$1"
    check "$1" "$2"
    if out="$(python3 -m ruff check --no-cache -q . 2>&1)"; then echo "PASS  $1: ruff clean"; else fail "$1: ruff"; printf '%s\n' "$out"; fi
  }
  # overlay <ref> <files...>: copy files from ref into the working tree. restore puts HEAD back.
  overlay() { ref="$1"; shift; g checkout -q "$ref" -- "$@"; }
  restore() { g checkout -q HEAD -- .; }
  same() { if [ "$(g rev-parse "$1^{commit}")" = "$(g rev-parse "$2^{commit}")" ]; then echo "PASS  $1 is at $2"; else fail "$1 is not at $2"; fi; }

  echo "Verifying..."
  at v1.4.0 11
  at issue-142-base 12
  at pr-149-weak 12
  at pr-151-merged 13
  at pr-153-merged 17
  at pr-158-merged 18
  at pr-161-weak 20
  at pr-163-merged 20
  at pr-170 21
  at pr-171 20

  same case/P-01 issue-142-base
  same case/P-03 pr-151-merged
  same case/P-02 pr-153-merged
  same case/P-04 pr-158-merged
  same case/P-06 pr-163-merged
  same main pr-163-merged
  same case/P-05 pr-170
  same "pr-161-weak^" case/P-04
  if g merge-base --is-ancestor pr-161-weak main || [ -n "$(g branch --contains pr-161-weak)" ]; then
    fail "pr-161-weak is on a branch"
  else echo "PASS  pr-161-weak is reachable only by its tag"; fi

  # P-01: the merged tests on code without the fix: the new test must fail, and the weak fix must fail them too.
  g checkout -q issue-142-base
  overlay pr-151-merged tests/test_shipments.py
  check "P-01 new test on issue-142-base code" fail tests/test_shipments.py::test_get_shipment_without_carrier
  restore
  g checkout -q pr-149-weak
  overlay pr-151-merged tests/test_shipments.py
  check "P-01 merged tests on pr-149-weak code" fail tests/test_shipments.py
  restore

  # P-03: the QA lead's tests pass on the case branch code (tests only, no app change).
  g checkout -q case/P-03
  overlay pr-153-merged tests/test_carriers.py
  check "P-03 pr-153 tests on case/P-03 code" 17
  restore
  if [ -z "$(g diff --name-only case/P-03 pr-153-merged -- app)" ]; then echo "PASS  P-03 pull request 153 changes no app code"
  else fail "P-03 pull request 153 changes app code"; fi

  # P-02: the regression test fails on the case branch code.
  g checkout -q case/P-02
  overlay pr-158-merged tests/test_shipments.py
  check "P-02 regression test on case/P-02 code" fail tests/test_shipments.py::test_search_with_apostrophe
  restore

  # P-04: the reference tests fail on the bug and pass with the fix; the weak tests do the opposite.
  g checkout -q case/P-04
  overlay pr-163-merged tests/test_admin.py
  check "P-04 reference tests on case/P-04 code" fail tests/test_admin.py
  overlay pr-163-merged app/routes/admin.py
  check "P-04 reference tests with the fixed admin.py overlaid" 20
  restore
  g checkout -q pr-161-weak
  check "P-04 pr-161-weak tests on the buggy code (why it is weak)" 4 tests/test_admin.py
  g checkout -q pr-163-merged
  overlay pr-161-weak tests/test_admin.py
  check "P-04 pr-161-weak tests at pr-163-merged" fail tests/test_admin.py
  restore

  # P-05 and P-06: the open pull requests.
  if g show pr-170:app/routes/admin.py | grep -A1 '^@router.get("/shipments/export")' | grep -q 'Depends(current_user)' \
     && ! g show pr-170:app/routes/admin.py | grep -A1 '^@router.get("/shipments/export")' | grep -q require_admin; then
    echo "PASS  pr-170 adds the export route without require_admin (app/routes/admin.py:$LINE)"
  else fail "pr-170 export route"; fi
  if [ "$(g diff --name-only pr-163-merged pr-171)" = "docs/api.md" ]; then echo "PASS  pr-171 changes only docs/api.md"
  else fail "pr-171 changes more than docs/api.md"; fi
  for b in pr-170 pr-171; do
    if [ "$(g rev-parse "$b^")" = "$(g rev-parse pr-163-merged)" ]; then echo "PASS  $b branches from pr-163-merged"
    else fail "$b does not branch from pr-163-merged"; fi
  done

  g checkout -q main
  find . \( -name __pycache__ -o -name .pytest_cache -o -name .ruff_cache \) -prune -exec rm -rf {} +
  if [ "$FAILS" -ne 0 ]; then echo "Verify: $FAILS check(s) FAILED" >&2; exit 1; fi
  echo "Verify: all checks PASSED"
fi

g checkout -q main
echo "Created $REPO"
echo "Created $EVAL (eval set for cases P-01 to P-06)"
g log --oneline --decorate --all
