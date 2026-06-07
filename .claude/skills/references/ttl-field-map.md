# TTL Field Map — Tremble Collections

Verified: 6 Jun 2026. Source of truth for all TTL/expiry field names.
Never assume — always check this table before writing CF code or Security Rules.

| Collection | Project | TTL field | Policy | Notes |
|---|---|---|---|---|
| `proximity_events` | tremble-dev + prod | `expiresAt` | 24h | Firebase TTL policy active |
| `run_encounters` | tremble-dev + prod | `expiresAt` | 24h | Firebase TTL policy active |
| `rateLimits` | tremble-dev + prod | `ttl` | 30d | Per-uid rate limit docs |
| `gdprRequests` | tremble-dev + prod | `ttl` | 30d | GDPR deletion requests |
| `proximity` (geohash) | tremble-dev | `geoHashExpiresAt` | custom | Add to prod when collection exists |
| `pulse_intercepts` | tremble-dev + prod | `expiresAt` | 10min | Pulse photo view-once TTL |

## DEAD fields — never use

| Field name | Status | Replaced by |
|---|---|---|
| `ttl` on proximity_events | ❌ WRONG — caused prod bug | `expiresAt` |
| `ttl` on run_encounters | ❌ WRONG — caused prod bug | `expiresAt` |

## How to verify TTL policy is active (prod)

```bash
gcloud firestore fields ttls list --database="(default)" --project=am---dating-app
```

Expected output includes `proximity_events.__ttl__` and `run_encounters.__ttl__` pointing to `expiresAt`.
