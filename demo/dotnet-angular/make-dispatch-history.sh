#!/usr/bin/env bash
# Builds the replay repository for the .NET and Angular practice kit, with one case branch per practice case.
# Commits on main, one per day:
#   1. chore: release 2.2.0                                                   (tag v2.2.0)
#   2. pull request 215, a lookup refactor that introduces NWD-212             (tag nwd-212-base, branch case/D-01)
#   3. pull request 219, a weak fix for NWD-212 that returns 404 and tests it  (tag pr-219-weak)
#   4. the revert of pull request 219 (#220)
#   5. pull request 221, the merged fix for NWD-212, with its regression test  (tag pr-221-merged, branch case/D-03)
#   6. pull request 224, tests for the list filter and sort by the QA lead     (tag pr-224-merged, branch case/D-02)
#   7. pull request 231, the merged fix for NWD-230 (stale typeahead results)  (tag pr-231-merged, branch case/D-04)
#   8. pull request 244, cancel requires a dispatcher, with its tests          (tag pr-244-merged, branches main and case/D-06)
# Off main, never merged:
#   - pull request 229, closed: debounceTime only, still stale                (tag pr-229-weak only, parent case/D-02)
#   - pull request 242, closed: cancel tests that assert the bug               (tag pr-242-weak only, parent case/D-04)
#   - pull request 250, open: CSV export, no admin policy                      (branches pr-250 and case/D-05)
#   - pull request 251, open: request examples in docs/api.md                  (branch pr-251)
# It also writes the eval set for cases D-01 to D-06 to <folder>/eval-set (outside the repository), and with
# --bundle, a git bundle of every branch and tag, which participants clone on any OS.
# Commit dates are fixed and user git config is ignored, so the commit hashes are the same on every machine.
# Usage: ./make-dispatch-history.sh [--verify] [--bundle <file>] ~/nwd-foundation
#   --verify  runs both test suites at each tag and checks every case. Needs the .NET 10 SDK and Node 22 with npm,
#             and downloads the NuGet and npm packages once.
set -euo pipefail
usage() { echo "Usage: make-dispatch-history.sh [--verify] [--bundle <file>] <folder to create>" >&2; exit 2; }
VERIFY=0 BUNDLE=""
while [ $# -gt 1 ]; do
  case "$1" in
    --verify) VERIFY=1; shift ;;
    --bundle) BUNDLE="${2:-}"; [ -n "$BUNDLE" ] || usage; shift 2 ;;
    *) usage ;;
  esac
done
if [ $# -ne 1 ] || [ -z "$1" ] || [ "${1#-}" != "$1" ]; then usage; fi
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$1"
REPO="$DEST/northwind-dispatch-portal"
EVAL="$DEST/eval-set"
for p in "$REPO" "$EVAL"; do
  if [ -e "$p" ]; then echo "$p already exists. Remove it first." >&2; exit 1; fi
done
if [ "$VERIFY" = 1 ]; then
  command -v dotnet >/dev/null 2>&1 && dotnet --version | grep -q '^10\.' || { echo "--verify needs the .NET 10 SDK on PATH" >&2; exit 1; }
  command -v node >/dev/null 2>&1 && node --version | grep -qE '^v(20|22)\.' || { echo "--verify needs Node 20 or 22 on PATH (Angular 19 does not support newer)" >&2; exit 1; }
fi
if [ -n "$BUNDLE" ]; then
  mkdir -p "$(dirname "$BUNDLE")"
  BUNDLE="$(cd "$(dirname "$BUNDLE")" && pwd)/$(basename "$BUNDLE")"
  [ -e "$BUNDLE" ] && { echo "$BUNDLE already exists. Remove it first." >&2; exit 1; }
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
REPO="$DEST/northwind-dispatch-portal"
EVAL="$DEST/eval-set"
CREATED=1
cp -R "$HERE/northwind-dispatch-portal" "$DEST/"
find "$REPO" \( -name .DS_Store -o -name bin -o -name obj -o -name node_modules -o -name dist -o -name .angular \) -prune -exec rm -rf {} +
cd "$REPO"

# Git ignores the user's config: no signing, no hooks, no global or system settings.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
g() { git -c commit.gpgsign=false -c tag.gpgsign=false -c core.hooksPath=/dev/null -c core.autocrlf=false "$@"; }
export GIT_AUTHOR_NAME="Northwind dispatch team" GIT_AUTHOR_EMAIL="dispatch-dev@northwind.example"
export GIT_COMMITTER_NAME="Northwind dispatch team" GIT_COMMITTER_EMAIL="dispatch-dev@northwind.example"
# Fixed dates make the hashes reproducible. Release 2.2.0 matches the CHANGELOG date.
on() { export GIT_AUTHOR_DATE="$1T10:00:00+0000" GIT_COMMITTER_DATE="$1T10:00:00+0000"; }
# pyedit runs the Python on stdin with edit(path, old, new), which replaces the one match and fails if the
# expected text is missing or ambiguous, so a change to the demo that breaks a step stops the build.
EDIT_PY='from pathlib import Path
def edit(path, old, new):
    p = Path(path)
    s = p.read_text()
    n = s.count(old)
    assert n == 1, f"{path}: expected text found {n} times: {old!r}"
    p.write_text(s.replace(old, new, 1))
def write(path, text):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)
SEARCH_SPEC = "web/src/app/dispatch-search/dispatch-search.component.spec.ts"
def search_spec_fake_async():
    # The search spec waits with fakeAsync and tick, so a component that debounces still passes it.
    s = SEARCH_SPEC
    edit(s, "import { TestBed } from \x27@angular/core/testing\x27;", "import { TestBed, fakeAsync, tick } from \x27@angular/core/testing\x27;")
    edit(s, "  it(\x27shows matches for the query\x27, () => {", "  it(\x27shows matches for the query\x27, fakeAsync(() => {")
    edit(s, "    typeInto(input, \x27NWD-1003\x27);\n    fixture.detectChanges();", "    typeInto(input, \x27NWD-1003\x27);\n    tick(500);\n    fixture.detectChanges();")
    edit(s, "    expect(items()).toEqual([\x27NWD-1003: Portland to Salem\x27]);\n  });", "    expect(items()).toEqual([\x27NWD-1003: Portland to Salem\x27]);\n  }));")
    edit(s, "  it(\x27does not search for fewer than two characters\x27, () => {", "  it(\x27does not search for fewer than two characters\x27, fakeAsync(() => {")
    edit(s, "    typeInto(input, \x27N\x27);\n    fixture.detectChanges();", "    typeInto(input, \x27N\x27);\n    tick(500);\n    fixture.detectChanges();")
    edit(s, "    expect(search).not.toHaveBeenCalled();\n  });", "    expect(search).not.toHaveBeenCalled();\n  }));")
'
pyedit() { python3 -c "$EDIT_PY$(cat)"; }
commit() { g add -A && g commit -q -m "$1"; }

# Release 2.2.0: before pull request 215, the lookup used the same null-safe projection as the list.
g init -q -b main
pyedit <<'PY'
edit("api/Controllers/DispatchesController.cs", """        var dispatch = await db.Dispatches.AsNoTracking().Include(d => d.Driver).FirstOrDefaultAsync(d => d.Id == id);
        if (dispatch is null)
        {
            return NotFound();
        }

        return new DispatchDto(dispatch.Id, dispatch.Reference, dispatch.Status.ToString(), dispatch.Origin,
            dispatch.Destination, dispatch.Driver!.Name, dispatch.CreatedAt, dispatch.Eta);""",
"""        var dispatch = await db.Dispatches.AsNoTracking()
            .Where(d => d.Id == id)
            .Select(d => new DispatchDto(d.Id, d.Reference, d.Status.ToString(), d.Origin, d.Destination,
                d.Driver == null ? null : d.Driver.Name, d.CreatedAt, d.Eta))
            .FirstOrDefaultAsync();

        return dispatch is null ? NotFound() : dispatch;""")
edit("CHANGELOG.md", """## Unreleased

- Dispatch lookup loads the dispatch with its driver, ready for the driver details screen (#215).

""", "")
PY
on 2026-08-03; commit "chore: release 2.2.0"; g tag v2.2.0

# Pull request 215: the lookup refactor. Restoring the tree as shipped gives the code with NWD-212.
cp "$HERE/northwind-dispatch-portal/api/Controllers/DispatchesController.cs" api/Controllers/DispatchesController.cs
cp "$HERE/northwind-dispatch-portal/CHANGELOG.md" CHANGELOG.md
on 2026-08-05; commit "refactor: load the dispatch with its driver on lookup (#215)"; g tag nwd-212-base
# Each case branch points at the commit before its pull request. Its history ends there, so a single-branch
# clone of the case branch (what the harness makes) contains neither the weak attempt nor the merged fix.
g branch case/D-01

# Pull request 219: a weak fix for NWD-212. It hides the exception as a 404, for a dispatch that exists,
# and adds a test that asserts the 404. Merged, then reverted by the backend lead.
pyedit <<'PY'
edit("api/Controllers/DispatchesController.cs", """        return new DispatchDto(dispatch.Id, dispatch.Reference, dispatch.Status.ToString(), dispatch.Origin,
            dispatch.Destination, dispatch.Driver!.Name, dispatch.CreatedAt, dispatch.Eta);""",
"""        try
        {
            return new DispatchDto(dispatch.Id, dispatch.Reference, dispatch.Status.ToString(), dispatch.Origin,
                dispatch.Destination, dispatch.Driver!.Name, dispatch.CreatedAt, dispatch.Eta);
        }
        catch (NullReferenceException)
        {
            return NotFound();
        }""")
edit("api.tests/DispatchesTests.cs", """    [Fact]
    public async Task Get_UnknownId_Returns404()""", """    [Fact]
    public async Task Get_DispatchWithoutDriver_Returns404()
    {
        var response = await api.ClientAs("dispatcher").GetAsync("/api/dispatches/3");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Get_UnknownId_Returns404()""")
PY
on 2026-08-07; commit "fix: dispatch lookup no longer returns a 500 (NWD-212) (#219)"; g tag pr-219-weak

# Pull request 220: revert 219. The tree is back to nwd-212-base.
g revert --no-edit HEAD >/dev/null
on 2026-08-08; g commit -q --amend -m 'Revert "fix: dispatch lookup no longer returns a 500 (NWD-212) (#219)"

This reverts pull request 219. A pending dispatch exists; it has no driver yet. (#220)'

# Pull request 221: the merged fix for NWD-212, with its regression test.
pyedit <<'PY'
edit("api/Controllers/DispatchesController.cs", "dispatch.Destination, dispatch.Driver!.Name, dispatch.CreatedAt, dispatch.Eta);",
     "dispatch.Destination, dispatch.Driver?.Name, dispatch.CreatedAt, dispatch.Eta);")
edit("api.tests/DispatchesTests.cs", """    [Fact]
    public async Task Get_UnknownId_Returns404()""", """    [Fact]
    public async Task Get_PendingDispatch_HasNoDriverName()
    {
        var dispatch = await api.ClientAs("dispatcher").GetFromJsonAsync<DispatchDto>("/api/dispatches/3");

        Assert.NotNull(dispatch);
        Assert.Equal("NWD-1003", dispatch.Reference);
        Assert.Equal("Pending", dispatch.Status);
        Assert.Null(dispatch.DriverName);
    }

    [Fact]
    public async Task Get_UnknownId_Returns404()""")
edit("CHANGELOG.md", "- Dispatch lookup loads the dispatch with its driver, ready for the driver details screen (#215).\n",
     "- Dispatch lookup loads the dispatch with its driver, ready for the driver details screen (#215).\n- Fix: looking up a dispatch with no driver yet returned a 500 (NWD-212) (#221).\n")
PY
on 2026-08-10; commit "fix: look up a dispatch that has no driver yet (NWD-212) (#221)"; g tag pr-221-merged
g branch case/D-03

# Pull request 224 (QA lead): tests only, for the list's status filter and sort. Seed order by createdAt is
# 1004, 1001, 1002, 1003; by eta 1004, 1002, 1001, then 1003, which has no eta. The controller is not changed.
pyedit <<'PY'
write("api.tests/DispatchListTests.cs", """using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc;
using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Tests;

public class DispatchListTests(DispatchApiFactory api) : IClassFixture<DispatchApiFactory>
{
    private async Task<string[]> References(string query)
    {
        var dispatches = await api.ClientAs("dispatcher").GetFromJsonAsync<List<DispatchDto>>("/api/dispatches" + query);
        return dispatches!.Select(d => d.Reference).ToArray();
    }

    [Fact]
    public async Task Sort_DefaultsToCreated()
    {
        Assert.Equal(["NWD-1004", "NWD-1001", "NWD-1002", "NWD-1003"], await References(""));
    }

    [Fact]
    public async Task Sort_ByEta_PutsDispatchesWithoutAnEtaLast()
    {
        Assert.Equal(["NWD-1004", "NWD-1002", "NWD-1001", "NWD-1003"], await References("?sort=eta"));
    }

    [Fact]
    public async Task Sort_ByReference()
    {
        Assert.Equal(["NWD-1001", "NWD-1002", "NWD-1003", "NWD-1004"], await References("?sort=reference"));
    }

    [Theory]
    [InlineData("InTransit", "NWD-1001")]
    [InlineData("pending", "NWD-1003")]
    public async Task Status_FiltersTheList_IgnoringCase(string status, string reference)
    {
        Assert.Equal([reference], await References($"?status={status}"));
    }

    [Fact]
    public async Task UnknownSort_Returns400NamingTheAllowedValues()
    {
        var response = await api.ClientAs("dispatcher").GetAsync("/api/dispatches?sort=driver");
        var problem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>();

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("created, eta, reference", Assert.Single(problem!.Errors["sort"]));
    }

    [Fact]
    public async Task UnknownStatus_Returns400()
    {
        var response = await api.ClientAs("dispatcher").GetAsync("/api/dispatches?status=Lost");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task List_AsCustomer_Returns403()
    {
        var response = await api.ClientAs("customer").GetAsync("/api/dispatches");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
""")
PY
on 2026-08-12; commit "test: cover the dispatch list filter and sort (#224)"; g tag pr-224-merged
g branch case/D-02

# Pull request 229, closed without merging: a weak fix for NWD-230. Waiting longer before searching makes the
# race rarer, but a slow first response still overwrites the newer one. Its tests move to fakeAsync, so its CI
# is green: only the merged race test catches it. Committed off main, kept by its tag.
g checkout -q --detach case/D-02
pyedit <<'PY'
edit("web/src/app/dispatch-search/dispatch-search.component.ts", "import { Subject, filter, map, mergeMap } from 'rxjs';",
     "import { Subject, debounceTime, filter, map, mergeMap } from 'rxjs';")
edit("web/src/app/dispatch-search/dispatch-search.component.ts", """      filter((query) => query.length >= 2),
      mergeMap((query) => this.dispatches.search(query)),""", """      filter((query) => query.length >= 2),
      debounceTime(300),
      mergeMap((query) => this.dispatches.search(query)),""")
search_spec_fake_async()
PY
on 2026-08-14; commit "fix: debounce the dispatch search (NWD-230) (#229)"; g tag pr-229-weak
g checkout -q main

# Pull request 231: the merged fix for NWD-230. switchMap drops the earlier request when a newer query arrives.
# The tests move to fakeAsync, so a fix that debounces still passes them, and a new test makes the earlier
# response arrive last.
pyedit <<'PY'
c = "web/src/app/dispatch-search/dispatch-search.component.ts"
edit(c, "import { Subject, filter, map, mergeMap } from 'rxjs';", "import { Subject, debounceTime, distinctUntilChanged, filter, map, switchMap } from 'rxjs';")
edit(c, """      filter((query) => query.length >= 2),
      mergeMap((query) => this.dispatches.search(query)),""", """      filter((query) => query.length >= 2),
      debounceTime(250),
      distinctUntilChanged(),
      switchMap((query) => this.dispatches.search(query)),""")
search_spec_fake_async()
s = SEARCH_SPEC
edit(s, "import { of } from 'rxjs';", "import { Subject, of } from 'rxjs';")
edit(s, "import { DispatchService } from '../dispatch.service';", "import { Dispatch, DispatchService } from '../dispatch.service';")
edit(s, """    expect(search).not.toHaveBeenCalled();
  }));
});""", """    expect(search).not.toHaveBeenCalled();
  }));

  it('shows results for the latest query, even when an earlier response arrives last (NWD-230)', fakeAsync(() => {
    const responses = new Map<string, Subject<Dispatch[]>>();
    search.mockImplementation((query: string) => {
      const response = new Subject<Dispatch[]>();
      responses.set(query, response);
      return response;
    });
    const { fixture, input, items } = render();

    typeInto(input, 'Po');
    tick(500);
    typeInto(input, 'Portland');
    tick(500);
    responses.get('Portland')!.next([aDispatch({ id: 1, reference: 'NWD-1001' })]);
    responses.get('Po')?.next([aDispatch({ id: 1, reference: 'NWD-1001' }), aDispatch({ id: 3, reference: 'NWD-1003', destination: 'Salem' })]);
    fixture.detectChanges();

    expect(items()).toEqual(['NWD-1001: Portland to Seattle']);
  }));
});""")
edit("CHANGELOG.md", "- Fix: looking up a dispatch with no driver yet returned a 500 (NWD-212) (#221).\n",
     "- Fix: looking up a dispatch with no driver yet returned a 500 (NWD-212) (#221).\n- Fix: the dispatch search could show results for an earlier query (NWD-230) (#231).\n")
PY
on 2026-08-17; commit "fix: dispatch search shows results for the latest query (NWD-230) (#231)"; g tag pr-231-merged
g branch case/D-04

# Pull request 242, closed without merging: tests for cancel that pass on the bug, because they assert that a
# customer gets a 204. Committed off main and kept only by its tag.
g checkout -q --detach case/D-04
pyedit <<'PY'
write("api.tests/CancelTests.cs", """using System.Net;

namespace Northwind.Dispatch.Api.Tests;

public class CancelTests(DispatchApiFactory api) : IClassFixture<DispatchApiFactory>
{
    [Fact]
    public async Task Cancel_AsDispatcher_Returns204()
    {
        var response = await api.ClientAs("dispatcher").PostAsync("/api/dispatches/2/cancel", null);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task Cancel_AsCustomer_Returns204()
    {
        var response = await api.ClientAs("customer").PostAsync("/api/dispatches/1/cancel", null);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task Cancel_Delivered_Returns409()
    {
        var response = await api.ClientAs("dispatcher").PostAsync("/api/dispatches/4/cancel", null);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }
}
""")
PY
on 2026-08-19; commit "test: cancel endpoint (#242)"; g tag pr-242-weak
g checkout -q main

# Pull request 244: cancel requires a dispatcher, with tests for a customer (403) and a dispatcher (204).
pyedit <<'PY'
edit("api/Controllers/DispatchesController.cs", """    [HttpPost("{id:int}/cancel")]
    public async Task<IActionResult> Cancel(int id)""", """    [HttpPost("{id:int}/cancel")]
    [Authorize(Policy = Policies.Dispatcher)]
    public async Task<IActionResult> Cancel(int id)""")
write("api.tests/CancelTests.cs", """using System.Net;
using System.Net.Http.Json;
using Northwind.Dispatch.Api.Models;

namespace Northwind.Dispatch.Api.Tests;

public class CancelTests(DispatchApiFactory api) : IClassFixture<DispatchApiFactory>
{
    [Fact]
    public async Task Cancel_AsDispatcher_CancelsTheDispatch()
    {
        var client = api.ClientAs("dispatcher");

        var response = await client.PostAsync("/api/dispatches/2/cancel", null);
        var dispatch = await client.GetFromJsonAsync<DispatchDto>("/api/dispatches/2");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal("Cancelled", dispatch!.Status);
    }

    [Fact]
    public async Task Cancel_AsCustomer_Returns403AndLeavesTheDispatch()
    {
        var response = await api.ClientAs("customer").PostAsync("/api/dispatches/1/cancel", null);
        var dispatch = await api.ClientAs("dispatcher").GetFromJsonAsync<DispatchDto>("/api/dispatches/1");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("InTransit", dispatch!.Status);
    }

    [Fact]
    public async Task Cancel_Delivered_Returns409()
    {
        var response = await api.ClientAs("dispatcher").PostAsync("/api/dispatches/4/cancel", null);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Cancel_UnknownId_Returns404()
    {
        var response = await api.ClientAs("dispatcher").PostAsync("/api/dispatches/999/cancel", null);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
""")
edit("CHANGELOG.md", "- Fix: the dispatch search could show results for an earlier query (NWD-230) (#231).\n",
     "- Fix: the dispatch search could show results for an earlier query (NWD-230) (#231).\n- Fix: any signed-in user, customers included, could cancel a dispatch (#244).\n")
PY
on 2026-08-21; commit "fix: cancelling a dispatch requires a dispatcher (#244)"; g tag pr-244-merged
g branch case/D-06

# Pull request 250, open: CSV export for the support team. The endpoint has no policy of its own, so the class's
# [Authorize] lets any signed-in customer download every customer's name, email and address. Otherwise clean:
# Csv.Field's leading apostrophe on =, +, - and @ is the standard guard against spreadsheet formula injection.
g checkout -q -b pr-250
pyedit <<'PY'
write("api/Csv.cs", """namespace Northwind.Dispatch.Api;

public static class Csv
{
    /// <summary>
    /// One CSV field. Quotes values with a comma, quote or line break, and prefixes an apostrophe to values that
    /// start with =, +, - or @, so a spreadsheet shows them as text instead of running them as a formula.
    /// </summary>
    public static string Field(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return "";
        }
        if ("=+-@".Contains(value[0]))
        {
            value = "'" + value;
        }
        return value.IndexOfAny([',', '"', '\\n', '\\r']) >= 0 ? "\\"" + value.Replace("\\"", "\\"\\"") + "\\"" : value;
    }
}
""")
edit("api/Controllers/DispatchesController.cs", """    /// <summary>Cancels a dispatch that has not been delivered.</summary>""", """    /// <summary>Every dispatch as CSV, with the customer's contact details, for the support team.</summary>
    [HttpGet("export")]
    public async Task<IActionResult> Export()
    {
        var rows = await db.Dispatches.AsNoTracking()
            .OrderBy(d => d.Reference)
            .Select(d => new { d.Reference, d.Status, d.Origin, d.Destination, Driver = d.Driver == null ? null : d.Driver.Name,
                Customer = d.Customer.Name, d.Customer.Email, d.Customer.Address, d.CreatedAt, d.Eta })
            .ToListAsync();

        var csv = new System.Text.StringBuilder("reference,status,origin,destination,driver,customer,email,address,createdAt,eta\\n");
        foreach (var r in rows)
        {
            csv.AppendJoin(',', Csv.Field(r.Reference), Csv.Field(r.Status.ToString()), Csv.Field(r.Origin), Csv.Field(r.Destination),
                Csv.Field(r.Driver), Csv.Field(r.Customer), Csv.Field(r.Email), Csv.Field(r.Address),
                r.CreatedAt.ToString("O"), r.Eta?.ToString("O") ?? "").Append('\\n');
        }
        return File(System.Text.Encoding.UTF8.GetBytes(csv.ToString()), "text/csv", "dispatches.csv");
    }

    /// <summary>Cancels a dispatch that has not been delivered.</summary>""")
write("api.tests/ExportTests.cs", """namespace Northwind.Dispatch.Api.Tests;

public class ExportTests(DispatchApiFactory api) : IClassFixture<DispatchApiFactory>
{
    [Fact]
    public async Task Export_ReturnsEveryDispatchAsCsv()
    {
        var response = await api.ClientAs("dispatcher").GetAsync("/api/dispatches/export");
        var lines = (await response.Content.ReadAsStringAsync()).TrimEnd().Split('\\n');

        Assert.Equal("text/csv", response.Content.Headers.ContentType?.MediaType);
        Assert.Equal("reference,status,origin,destination,driver,customer,email,address,createdAt,eta", lines[0]);
        Assert.Equal(5, lines.Length);
    }

    [Theory]
    [InlineData("=SUM(A1)", "'=SUM(A1)")]
    [InlineData("Portland, OR", "\\"Portland, OR\\"")]
    [InlineData("Seattle", "Seattle")]
    public void Field_GuardsFormulasAndQuotesCommas(string value, string expected)
    {
        Assert.Equal(expected, Csv.Field(value));
    }
}
""")
edit("web/src/app/dispatch.service.ts", """  cancel(id: number): Observable<void> {""", """  exportCsv(): Observable<Blob> {
    return this.http.get('/api/dispatches/export', { responseType: 'blob' });
  }

  cancel(id: number): Observable<void> {""")
edit("web/src/app/dispatch.service.spec.ts", """  it('cancels with a POST', () => {""", """  it('downloads the export as a blob', () => {
    let result: Blob | undefined;
    service.exportCsv().subscribe((blob) => (result = blob));

    const request = http.expectOne('/api/dispatches/export');
    expect(request.request.responseType).toBe('blob');
    request.flush(new Blob(['reference\\n']));

    expect(result).toBeInstanceOf(Blob);
  });

  it('cancels with a POST', () => {""")
edit("web/src/app/dispatch-board/dispatch-board.component.ts", """        </select>
      </label>""", """        </select>
      </label>
      <button type="button" (click)="exportCsv()">Export CSV</button>""")
edit("web/src/app/dispatch-board/dispatch-board.component.ts", """  cancel(dispatch: Dispatch): void {""", """  exportCsv(): void {
    this.service.exportCsv().subscribe((blob) => {
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'dispatches.csv';
      link.click();
      URL.revokeObjectURL(link.href);
    });
  }

  cancel(dispatch: Dispatch): void {""")
edit("docs/api.md", "| `POST /api/dispatches/{id}/cancel` | Dispatcher | 204; 404 if unknown; 409 if delivered |",
     "| `POST /api/dispatches/{id}/cancel` | Dispatcher | 204; 404 if unknown; 409 if delivered |\n| `GET /api/dispatches/export` | signed in | Every dispatch as CSV, with the customer's name, email, and address |")
edit("CHANGELOG.md", "- Fix: any signed-in user, customers included, could cancel a dispatch (#244).\n",
     "- Fix: any signed-in user, customers included, could cancel a dispatch (#244).\n- Export dispatches as CSV for the support team (#250).\n")
PY
on 2026-08-24; commit "feat: export dispatches as CSV (#250)"
g branch case/D-05
g checkout -q main

# Pull request 251, open: docs only.
g checkout -q -b pr-251
pyedit <<'PY'
edit("docs/api.md", "## Endpoints\n", """## Examples

Requests go through the gateway, which adds the two headers. To call the API directly while developing:

```bash
curl -H "X-Northwind-User: dana" -H "X-Northwind-Role: dispatcher" http://localhost:5080/api/dispatches?sort=eta
curl -H "X-Northwind-User: dana" -H "X-Northwind-Role: dispatcher" "http://localhost:5080/api/dispatches/search?q=NWD-10"
```

## Endpoints
""")
PY
on 2026-08-25; commit "docs: add request examples to docs/api.md (#251)"
g checkout -q main

# The eval set, outside the repository so Claude cannot read it during a run. Each case's case.json holds the
# options run-case.cs needs; paths in it are relative to the eval-set folder.
for c in D-01 D-02 D-03 D-04 D-05 D-06; do mkdir -p "$EVAL/$c"; done
mkdir -p "$EVAL/outputs"
python3 - "$EVAL" <<'PY'
import json, os, sys
ev = sys.argv[1]
code_allow = ["Bash(dotnet test *)", "Bash(dotnet test)", "Bash(dotnet build *)", "Bash(dotnet build)",
              "Bash(npm --prefix web test)", "Bash(npm --prefix web test *)"]
git_allow = ["Bash(git log *)", "Bash(git show *)", "Bash(git diff *)", "Bash(git branch *)"]
setup = "dotnet restore NorthwindDispatch.slnx && npm --prefix web ci --no-audit --no-fund"
api, web = "dotnet test NorthwindDispatch.slnx", "npm --prefix web test"
cases = {
    "D-01": dict(branch="case/D-01", setup=setup, test=api, allow=code_allow,
                 referenceRef="pr-221-merged", referenceFiles=["api.tests/DispatchesTests.cs"]),
    "D-02": dict(branch="case/D-02", setup=setup, test=web, allow=code_allow,
                 referenceRef="pr-231-merged", referenceFiles=["web/src/app/dispatch-search/dispatch-search.component.spec.ts"]),
    "D-03": dict(branch="case/D-03", setup=setup, test=api, allow=code_allow),
    "D-04": dict(branch="case/D-04", setup=setup, test=api, allow=code_allow,
                 referenceRef="pr-244-merged", referenceFiles=["api/Controllers/DispatchesController.cs"], checkBefore=True),
    "D-05": dict(branch="case/D-05", allow=git_allow),
    "D-06": dict(branch="case/D-06", allow=git_allow, extraBranches=["pr-250", "pr-251"]),
}
for cid, c in cases.items():
    c = {"case": cid, "repo": "../northwind-dispatch-portal", "request": "request.md", **c}
    json.dump(c, open(os.path.join(ev, cid, "case.json"), "w"), indent=2)
    open(os.path.join(ev, cid, "case.json"), "a").write("\n")
# The model and run count every case in this eval set uses. Set the model to the one the team uses day to day.
json.dump({"model": "sonnet", "runs": 3}, open(os.path.join(ev, "eval-run.json"), "w"), indent=2)
PY

RUNIT='Run it from any terminal (PowerShell, bash, or zsh). run-case reads this case'"'"'s case.json, so the command is the same everywhere:'
# context <case> <title> <facts...>: writes the case's context.md with its facts and the run command.
context() {
  id="$1"; title="$2"; shift 2
  { echo "# Case $id context: $title"; echo
    for fact in "$@"; do echo "- $fact"; done
    echo; echo "## Run it"; echo; echo "$RUNIT"; echo
    printf '```\nrun-case --eval-set ~/nwd-foundation/eval-set --case %s\n```\n' "$id"; echo
    echo "## How to grade"; echo
    cat
  } > "$EVAL/$id/context.md"
}

# D-01: bug fix from NWD-212.
cat > "$EVAL/D-01/request.md" <<'EOF'
Fix NWD-212: GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet. Pending dispatches don't have a driver until a dispatcher assigns one, so this is valid data.
EOF
context D-01 "bug fix from a Jira issue" "Repository: northwind-dispatch-portal" "Pull request: 221 (the merged fix for NWD-212)" \
  "Commit before: nwd-212-base" "Merged ref: pr-221-merged" "Test added: Get_PendingDispatch_HasNoDriverName" \
  "Test files to copy in: api.tests/DispatchesTests.cs" "Suite command: \`dotnet test NorthwindDispatch.slnx\`" \
  "Case branch: case/D-01" "Type: Capability" "Should Claude ask first? No" <<'EOF'
Automatable grader: the merged pull request's api.tests/DispatchesTests.cs is copied into each run, then the API
suite runs. "What we noticed" says "Reference tests: pass" or "fail". Then read the run's .diff against note.md:
weak.diff (pull request 219) passes its own new test but fails the merged ones.
EOF
cat > "$EVAL/D-01/note.md" <<'EOF'
Backend lead approved. A dispatch with no driver returns 200, with driverName null (docs/api.md). Returning 404 or an empty string, or catching the exception, is a Fail, and so is editing an existing test. weak.diff (pull request 219) returns 404 for a dispatch that exists, and adds a test that asserts it.
EOF
g diff --no-color --no-ext-diff nwd-212-base pr-221-merged > "$EVAL/D-01/reference.diff"
g diff --no-color --no-ext-diff nwd-212-base pr-219-weak > "$EVAL/D-01/weak.diff"

# D-02: bug fix from NWD-230, in the Angular app.
cat > "$EVAL/D-02/request.md" <<'EOF'
Fix NWD-230: the dispatch search box sometimes shows results for an earlier query. Type "Po", pause, then finish typing "Portland": when the first request is slow, its results replace the ones for "Portland".
EOF
context D-02 "bug fix from a Jira issue (Angular)" "Repository: northwind-dispatch-portal" "Pull request: 231 (the merged fix for NWD-230)" \
  "Commit before: pr-224-merged" "Merged ref: pr-231-merged" "Test added: shows results for the latest query, even when an earlier response arrives last" \
  "Test files to copy in: web/src/app/dispatch-search/dispatch-search.component.spec.ts" "Suite command: \`npm --prefix web test\`" \
  "Case branch: case/D-02" "Type: Capability" "Should Claude ask first? No" <<'EOF'
Automatable grader: the merged pull request's dispatch-search.component.spec.ts is copied into each run, then the
web suite runs. Its tests wait with fakeAsync, so a correct fix that also debounces passes them. The race test makes
the earlier response arrive last: only a fix that drops earlier requests passes it. weak.diff (pull request 229)
passes its own tests and fails the race test.
EOF
cat > "$EVAL/D-02/note.md" <<'EOF'
Frontend lead approved. The search drops the earlier request when a newer query arrives: switchMap, or an equivalent that cancels it. debounceTime alone is a Fail (weak.diff, pull request 229): its tests pass, but a slow earlier response still wins. Existing tests may move to fakeAsync and tick; their assertions must not change.
EOF
g diff --no-color --no-ext-diff case/D-02 pr-231-merged > "$EVAL/D-02/reference.diff"
g diff --no-color --no-ext-diff case/D-02 pr-229-weak > "$EVAL/D-02/weak.diff"

# D-03: tests for the list's filter and sort (code that already works).
cat > "$EVAL/D-03/request.md" <<'EOF'
Write tests for GET /api/dispatches: the status filter and the sort parameter, including the 400 for an unknown sort.
EOF
context D-03 "unit tests for changed code" "Repository: northwind-dispatch-portal" "Pull request: 224 (the QA lead's tests)" \
  "Commit before: pr-221-merged" "Merged ref: pr-224-merged" "Suite command: \`dotnet test NorthwindDispatch.slnx\`" \
  "Case branch: case/D-03" "Type: Capability" "Should Claude ask first? No" <<'EOF'
Automatable grader: the suite runs as Claude left it. The code already works, so the new tests should pass; the
reviewer then checks what they cover and how they are written, against note.md and reference.diff.
EOF
cat > "$EVAL/D-03/note.md" <<'EOF'
QA lead approved. A test per sort value (created, eta, reference), the eta order with the dispatch that has no eta last, the status filter, and the 400 for an unknown sort naming the allowed values. The tests use IClassFixture<DispatchApiFactory> and ClientAs (CLAUDE.md), and the controller is unchanged. A hand-built HttpClient or a new factory fails the conventions.
EOF
g diff --no-color --no-ext-diff case/D-03 pr-224-merged > "$EVAL/D-03/reference.diff"

# D-04: tests for cancel, which any signed-in user can call. Good tests fail on the bug.
cat > "$EVAL/D-04/request.md" <<'EOF'
Add tests for POST /api/dispatches/{id}/cancel.
EOF
context D-04 "unit tests that must catch a bug" "Repository: northwind-dispatch-portal" "Pull request: 244 (cancel requires a dispatcher, with its tests)" \
  "Commit before: pr-231-merged" "Merged ref: pr-244-merged" "Fixed code to overlay: api/Controllers/DispatchesController.cs" \
  "Suite command: \`dotnet test NorthwindDispatch.slnx\`" "Case branch: case/D-04" "Type: Capability" "Should Claude ask first? No" <<'EOF'
Automatable grader (check-before): the API suite runs twice. First on today's code as Claude left it: good tests
fail here, because a customer can cancel. Then with the fixed controller from pull request 244 copied in: good tests
pass. weak.diff (pull request 242) does the opposite.
EOF
cat > "$EVAL/D-04/note.md" <<'EOF'
QA lead approved. The tests catch the bug: a customer who cancels gets 403, and the dispatch is unchanged. On today's code that test fails, which is the point; with the fixed controller (pr-244-merged) every test passes. weak.diff (pull request 242) asserts that a customer gets 204: it passes on the bug and is a Fail. A run that also fixes the controller, and says so, is fine; tests that pass on today's code are a Fail.
EOF
g diff --no-color --no-ext-diff case/D-04 pr-244-merged > "$EVAL/D-04/reference.diff"
g diff --no-color --no-ext-diff case/D-04 pr-242-weak > "$EVAL/D-04/weak.diff"

# D-05: review of pull request 250. The finding's line number is read from the branch.
LINE="$(g show pr-250:api/Controllers/DispatchesController.cs | grep -n 'HttpGet("export")' | cut -d: -f1)"
cat > "$EVAL/D-05/request.md" <<'EOF'
Review pull request 250 against docs/review-checklist.md. Its change is the most recent commit on this branch.
EOF
context D-05 "pull request review" "Repository: northwind-dispatch-portal" "Pull request: 250 (open: export dispatches as CSV)" \
  "Case branch: case/D-05 (the pull request's head)" "Type: Capability" "Should Claude ask first? No" <<'EOF'
Review case: nothing runs a test. Read the reply (.md) against note.md and reference.md. The .diff should be empty.
EOF
cat > "$EVAL/D-05/note.md" <<'EOF'
Staff engineer's review blocked it. The review flags GET /api/dispatches/export: it names no policy, so any signed-in customer downloads every customer's name, email and address (checklist item 1: data across customers needs Policies.Admin), with the file and line. Flagging Csv.Field's leading apostrophe as a bug is a Fail: it is the guard against spreadsheet formula injection. Comments on style alone don't count.
EOF
cat > "$EVAL/D-05/reference.md" <<EOF
Blocking: api/Controllers/DispatchesController.cs:$LINE. GET /api/dispatches/export has no policy of its own, so the
controller's [Authorize] applies: any signed-in user, customers included, can download every dispatch with every
customer's name, email and address. The checklist (item 1) says data across customers needs Policies.Admin. Add
[Authorize(Policy = Policies.Admin)], add a test that a customer gets 403, and update the policy in docs/api.md.

Everything else checks out. Csv.Field's apostrophe on values starting with =, +, - or @ is the right guard against
spreadsheet formula injection, and the field quoting is correct. The CHANGELOG line is there.
EOF

# D-06: "Review this", with two pull requests open.
cat > "$EVAL/D-06/request.md" <<'EOF'
Review this.
EOF
context D-06 "pull request review (ambiguous request)" "Repository: northwind-dispatch-portal" "Open pull requests: 250 (branch pr-250) and 251 (branch pr-251)" \
  "Case branch: case/D-06 (main), with pr-250 and pr-251 copied in" "Type: Capability" "Should Claude ask first? Yes" <<'EOF'
Review case: nothing runs a test. Read the reply (.md): does it ask which pull request to review before reviewing?
EOF
cat > "$EVAL/D-06/note.md" <<'EOF'
Staff engineer approved. With two open pull requests, the reply asks which one, 250 or 251, before reviewing. Picking a pull request without asking is a Fail, even when the review itself is good (weak.md reviewed 251 without asking).
EOF
cat > "$EVAL/D-06/reference.md" <<'EOF'
Two pull requests are open: 250 (export dispatches as CSV, on pr-250) and 251 (request examples in docs/api.md, on
pr-251). Which one should I review? I'll check it against docs/review-checklist.md.
EOF
cat > "$EVAL/D-06/weak.md" <<'EOF'
Reviewed pull request 251 (docs: add request examples to docs/api.md). The examples are correct and match the
gateway headers. No issues; approve.
EOF

# The content of templates/eval-run-settings.json, plus claudeMdExcludes for this machine's personal CLAUDE.md
# and rules (it only matches absolute paths, so the shared template cannot carry it). run-case adds the same.
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
  export DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1
  # The npm packages are installed once, outside the repository, and linked into web/ for every checkout.
  NM="$(mktemp -d)"
  trap 'rm -rf "$NM"' EXIT
  cp web/package.json web/package-lock.json "$NM/"
  (cd "$NM" && npm ci --no-audit --no-fund >/dev/null 2>&1) || { echo "npm ci failed" >&2; exit 1; }
  ln -s "$NM/node_modules" web/node_modules
  echo "web/node_modules" >> .git/info/exclude
  # result <label> <want: passed count or "fail"> <rc> <passed count> <output>
  result() {
    if [ "$2" = fail ]; then
      if [ "$3" -ne 0 ]; then echo "PASS  $1: fails as expected"; else fail "$1: expected a failure, got exit 0"; fi
    elif [ "$3" -eq 0 ] && [ "$4" = "$2" ]; then echo "PASS  $1: $4 passed"
    else fail "$1: expected $2 passed, got ${4:-0} passed (exit $3)"; printf '%s\n' "$5" | tail -15; fi
  }
  # api <label> <want> [dotnet test args...]: the API suite. web <label> <want> [jest path]: the web suite.
  api() {
    label="$1"; want="$2"; shift 2
    if out="$(dotnet test NorthwindDispatch.slnx "$@" 2>&1)"; then rc=0; else rc=$?; fi
    result "$label" "$want" "$rc" "$(printf '%s\n' "$out" | grep -Eo 'Passed: +[0-9]+' | tail -1 | grep -Eo '[0-9]+' || true)" "$out"
  }
  web() {
    label="$1"; want="$2"; shift 2
    if out="$(cd web && npx --no-install jest "$@" 2>&1)"; then rc=0; else rc=$?; fi
    result "$label" "$want" "$rc" "$(printf '%s\n' "$out" | grep -E '^Tests:' | grep -Eo '[0-9]+ passed' | grep -Eo '[0-9]+' || true)" "$out"
  }
  # at <ref> <api count> <web count>: both suites at a tag or branch.
  at() { g checkout -q "$1"; api "$1 api" "$2"; web "$1 web" "$3"; }
  # overlay <ref> <files...>: copy files from ref into the working tree. restore puts HEAD back, and removes files
  # an overlay added (ignored paths, such as bin/, obj/ and the linked node_modules, are left alone).
  overlay() { ref="$1"; shift; g checkout -q "$ref" -- "$@"; }
  restore() { g reset -q HEAD -- . && g checkout -q HEAD -- . && g clean -qfd -- .; }
  same() { if [ "$(g rev-parse "$1^{commit}")" = "$(g rev-parse "$2^{commit}")" ]; then echo "PASS  $1 is at $2"; else fail "$1 is not at $2"; fi; }
  tagonly() {
    if g merge-base --is-ancestor "$1" main || [ -n "$(g branch --contains "$1")" ]; then fail "$1 is on a branch"
    else echo "PASS  $1 is reachable only by its tag"; fi
  }

  echo "Verifying..."
  at v2.2.0 8 7
  at nwd-212-base 8 7
  at pr-219-weak 9 7
  at pr-221-merged 9 7
  at pr-224-merged 17 7
  at pr-229-weak 17 7
  at pr-231-merged 17 8
  at pr-242-weak 20 8
  at pr-244-merged 21 8
  at pr-250 25 9
  at pr-251 21 8

  same case/D-01 nwd-212-base
  same case/D-03 pr-221-merged
  same case/D-02 pr-224-merged
  same case/D-04 pr-231-merged
  same case/D-06 pr-244-merged
  same main pr-244-merged
  same case/D-05 pr-250
  same "pr-229-weak^" case/D-02
  same "pr-242-weak^" case/D-04
  tagonly pr-229-weak
  tagonly pr-242-weak

  # D-01: the merged tests on the code without the fix fail, and on the weak fix too.
  g checkout -q nwd-212-base
  overlay pr-221-merged api.tests/DispatchesTests.cs
  api "D-01 new test on nwd-212-base code" fail --filter Get_PendingDispatch_HasNoDriverName
  restore
  g checkout -q pr-219-weak
  overlay pr-221-merged api.tests/DispatchesTests.cs
  api "D-01 merged tests on pr-219-weak code" fail
  restore

  # D-02: the merged spec fails on the case branch code and on the weak fix, whose own tests pass.
  g checkout -q case/D-02
  overlay pr-231-merged web/src/app/dispatch-search/dispatch-search.component.spec.ts
  web "D-02 merged spec on case/D-02 code" fail src/app/dispatch-search
  restore
  g checkout -q pr-229-weak
  web "D-02 pr-229-weak passes its own tests" 7
  overlay pr-231-merged web/src/app/dispatch-search/dispatch-search.component.spec.ts
  web "D-02 merged spec on pr-229-weak code" fail src/app/dispatch-search
  restore

  # D-03: the QA lead's tests pass on the case branch code, and pull request 224 changes no API code.
  g checkout -q case/D-03
  overlay pr-224-merged api.tests/DispatchListTests.cs
  api "D-03 pr-224 tests on case/D-03 code" 17
  restore
  if [ -z "$(g diff --name-only case/D-03 pr-224-merged -- api)" ]; then echo "PASS  D-03 pull request 224 changes no API code"
  else fail "D-03 pull request 224 changes API code"; fi

  # D-04: the reference tests fail on the bug and pass with the fix; the weak tests do the opposite.
  g checkout -q case/D-04
  overlay pr-244-merged api.tests/CancelTests.cs
  api "D-04 reference tests on case/D-04 code" fail
  overlay pr-244-merged api/Controllers/DispatchesController.cs
  api "D-04 reference tests with the fixed controller overlaid" 21
  restore
  g checkout -q pr-242-weak
  api "D-04 pr-242-weak tests on the buggy code (why it is weak)" 20
  overlay pr-244-merged api/Controllers/DispatchesController.cs
  api "D-04 pr-242-weak tests with the fixed controller" fail
  restore

  # D-05 and D-06: the open pull requests.
  if g show pr-250:api/Controllers/DispatchesController.cs | sed -n "$((LINE + 1))p" | grep -q 'Authorize'; then
    fail "pr-250's export route has a policy"
  else echo "PASS  pr-250 adds the export route without a policy (api/Controllers/DispatchesController.cs:$LINE)"; fi
  if [ "$(g diff --name-only pr-244-merged pr-251)" = "docs/api.md" ]; then echo "PASS  pr-251 changes only docs/api.md"
  else fail "pr-251 changes more than docs/api.md"; fi
  for b in pr-250 pr-251; do
    if [ "$(g rev-parse "$b^")" = "$(g rev-parse pr-244-merged)" ]; then echo "PASS  $b branches from pr-244-merged"
    else fail "$b does not branch from pr-244-merged"; fi
  done

  g checkout -q main
  rm web/node_modules
  sed -i.bak '/^web\/node_modules$/d' .git/info/exclude && rm -f .git/info/exclude.bak
  g clean -qfdX -- api api.tests web
  if [ -n "$(g status --porcelain --ignored)" ]; then fail "the working tree is not clean after verifying"; g status --short --ignored | head; fi
  if [ "$FAILS" -ne 0 ]; then echo "Verify: $FAILS check(s) FAILED"; exit 1; fi
  echo "Verify: all checks PASSED"
fi

if [ -n "$BUNDLE" ]; then
  g bundle create -q "$BUNDLE" --all
  g bundle verify -q "$BUNDLE" >/dev/null && echo "Bundle: $BUNDLE ($(g bundle list-heads "$BUNDLE" | wc -l | tr -d ' ') refs)"
fi
echo "Created $REPO"
echo "Created $EVAL (eval set for cases D-01 to D-06)"
g log --oneline --decorate --all
