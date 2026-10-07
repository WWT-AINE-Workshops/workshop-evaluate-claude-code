# Northwind Dispatch Portal

ASP.NET Core 10 API in `api/`, Angular 19 app in `web/`. Read `docs/api.md` before changing a response, and `docs/review-checklist.md` before reviewing.

## Commands

- API tests: `dotnet test NorthwindDispatch.slnx`
- Web tests: `npm --prefix web test`

## Conventions

- Every endpoint names its authorization policy (`Policies.Dispatcher` or `Policies.Admin`). `[Authorize]` alone means "any signed-in user", customers included.
- Response shapes are part of the contract. Don't rename, drop, or retype a field in `DispatchDto` without updating `docs/api.md` and calling it out in the pull request.
- API tests use `IClassFixture<DispatchApiFactory>` and sign in with `api.ClientAs(role)`. Don't build an `HttpClient` by hand.
- Web tests stub `DispatchService` with `{ provide: DispatchService, useValue: ... }`, or use `HttpTestingController` for the service itself. Build test data with `aDispatch()` from `web/src/app/testing.ts`.
- Never edit an existing test to make it pass. If a test is wrong, say so in the pull request.
