# Review of pull request 170: feat: export shipments as CSV

Request changes.

## Blocking

**High: the export route does not require an admin (checklist item 2).**
`app/routes/admin.py:24`: `export_shipments` depends on `current_user`, so any signed-in customer can
download every customer's shipments, recipient names and destinations included. Every other admin route
depends on `require_admin`, and docs/api.md lists this one as Admin. Use `Depends(require_admin)`, and add a
test that a customer gets 403 from `GET /admin/shipments/export` (checklist item 4, the failure path).

## Checked, no findings

- Scope matches the pull request (item 1).
- No user input reaches the SQL (item 3).
- docs/api.md and CHANGELOG.md are updated (item 5).
- No secrets or personal data in code or tests (item 6).
