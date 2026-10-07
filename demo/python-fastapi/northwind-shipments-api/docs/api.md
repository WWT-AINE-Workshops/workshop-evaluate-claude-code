# API reference

All endpoints except `/health` and `POST /sessions` need a bearer token from `POST /sessions`.

| Method | Path | Who | What it does |
|---|---|---|---|
| GET | /health | Anyone | Liveness check |
| POST | /sessions | Anyone | Sign in; returns an access token |
| GET | /shipments/search?q= | Customer | Search your shipments by reference or recipient name |
| GET | /shipments/{id} | Customer | One of your shipments |
| POST | /shipments | Customer | Create a shipment |
| GET | /carriers?sort=&min_on_time= | Customer | Carrier directory; sort by name, code, or on_time |
| GET | /admin/users | Admin | List users |
| DELETE | /admin/shipments/{id} | Admin | Delete a shipment |
| POST | /webhooks/test | Customer | Send a test event to a carrier callback URL |
| POST | /reports/import | Admin | Bulk status update from a carrier YAML report |

Errors return JSON with an `error` field.
