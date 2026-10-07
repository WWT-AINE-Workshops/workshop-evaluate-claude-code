Blocking: api/Controllers/DispatchesController.cs:92. GET /api/dispatches/export has no policy of its own, so the
controller's [Authorize] applies: any signed-in user, customers included, can download every dispatch with every
customer's name, email and address. The checklist (item 1) says data across customers needs Policies.Admin. Add
[Authorize(Policy = Policies.Admin)], add a test that a customer gets 403, and update the policy in docs/api.md.

Everything else checks out. Csv.Field's apostrophe on values starting with =, +, - or @ is the right guard against
spreadsheet formula injection, and the field quoting is correct. The CHANGELOG line is there.
