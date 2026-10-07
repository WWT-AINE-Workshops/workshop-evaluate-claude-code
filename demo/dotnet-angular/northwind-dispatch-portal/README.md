# Northwind Dispatch Portal

The dispatch portal for Northwind Freight's regional delivery team: an ASP.NET Core API (`api/`) and an Angular single-page app (`web/`). Dispatchers plan and track deliveries; customers see their own through the customer portal, which calls the same API.

> **Fictional.** Northwind Freight, its people, and this repository are practice material for a Claude Code workshop. The code contains deliberate weaknesses. Never deploy it.

## Run it

```bash
dotnet run --project api --urls http://localhost:5080
cd web && npm ci && npm start
```

## Test it

```bash
dotnet test NorthwindDispatch.slnx
cd web && npm test
```

The API tests start the API in memory on a fresh SQLite database (`api.tests/DispatchApiFactory.cs`). The web tests run headless under Jest.

## Layout

| Path | What it is |
|---|---|
| `api/` | ASP.NET Core 10 controllers, EF Core on SQLite (SQL Server in production), gateway sign-in |
| `api.tests/` | xUnit tests through `WebApplicationFactory` |
| `web/` | Angular 19 standalone components, RxJS, Jest |
| `docs/api.md` | The API contract |
| `docs/review-checklist.md` | What reviewers check on every pull request |
| `buildspec.yml` | AWS CodeBuild: build and test |
