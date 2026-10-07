# Dispatch API

Every endpoint except `/health` needs a signed-in user. The gateway sends `X-Northwind-User` and `X-Northwind-Role` (`customer`, `dispatcher`, or `admin`).

## The dispatch object

| Field | Type | Notes |
|---|---|---|
| `id` | number | |
| `reference` | string | Such as `NWD-1001` |
| `status` | string | `Pending`, `Assigned`, `InTransit`, `Delivered`, or `Cancelled` |
| `origin`, `destination` | string | |
| `driverName` | string or null | Null while no driver is assigned. Pending dispatches have none |
| `createdAt` | string | UTC, ISO 8601 |
| `eta` | string or null | UTC, ISO 8601 |

## Endpoints

| Method and path | Policy | Returns |
|---|---|---|
| `GET /health` | none | `{"status": "ok"}` |
| `GET /api/dispatches?status=&sort=` | Dispatcher | Dispatches, sorted by `created` (default), `eta`, or `reference`. An unknown `sort` or `status` is a 400 that names the allowed values |
| `GET /api/dispatches/{id}` | Dispatcher | One dispatch, or 404 |
| `GET /api/dispatches/search?q=` | Dispatcher | Up to 10 dispatches whose reference or destination contains `q`. Fewer than two characters returns `[]` |
| `POST /api/dispatches/{id}/cancel` | Dispatcher | 204; 404 if unknown; 409 if delivered |
