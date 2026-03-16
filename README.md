# test_dbs

Docker Compose stack for quickly spinning up PostgreSQL, Redis, MinIO, and Qdrant for development/testing, with optional Cloudflare Zero Trust tunnel support for cloud deployments.

## Services

| Service    | Image            | Default Port(s)   | Purpose                     |
|------------|------------------|--------------------|-----------------------------|
| PostgreSQL | `postgres:17`    | 5432               | Relational database         |
| Redis      | `redis:7`        | 6379               | In-memory key-value store   |
| MinIO      | `minio/minio`    | 9000 (API), 9001 (Console) | S3-compatible object storage |
| Qdrant     | `qdrant/qdrant`  | 6333 (HTTP), 6334 (gRPC) | Vector database             |
| Cloudflared (optional) | `cloudflare/cloudflared` | n/a | Cloudflare Zero Trust tunnel (cloud profile only) |

## Quick Start

```bash
cp .env.example .env    # copy and edit credentials/ports as needed
chmod +x ./stack-up.sh
./stack-up.sh           # auto mode: LAN by default, cloud when tunnel token is set
docker compose ps       # verify everything is healthy
```

`stack-up.sh` behavior:
- If `CLOUDFLARED_TUNNEL_TOKEN` is set (for example in `.env`), runs: `docker compose --profile cloud up -d`
- If not set, runs: `docker compose up -d`

## Connection Details

Defaults (override in `.env`):

**PostgreSQL**
```
postgresql://testuser:testpass@<host>:5432/testdb
```

**Redis**
```
redis://:testpass@<host>:6379
```

**MinIO**
```
Endpoint:   http://<host>:9000
Console:    http://<host>:9001
Access Key: minioadmin
Secret Key: minioadmin
```

**Qdrant**
```
HTTP: http://<host>:6333
gRPC: <host>:6334
```

## Management

```bash
docker compose logs -f          # tail all logs
docker compose down             # stop services (data persists in volumes)
docker compose down -v          # stop and destroy all data
./stack-up.sh <service>         # auto profile-aware start for specific service(s)
docker compose up -d <service>  # manual start for specific service(s)
```

Data is stored in Docker named volumes (`pgdata`, `redisdata`, `miniodata`, `qdrantdata`) and survives `docker compose down` unless `-v` is passed.

## MinIO Familiar Artifact Policy (`kimini` bucket)

The `kimini` bucket stores familiar pipeline artifacts. Prefixes are virtual and are created automatically on first write. Do not pre-create empty prefixes.

| Prefix | Contents | Retention |
|---|---|---|
| `familiar/datasets/{familiar_id}/{version}/` | Training images, resized copies | Indefinite |
| `familiar/captions/{familiar_id}/{version}/` | Caption `.txt` files per image | Indefinite |
| `familiar/adapters/{familiar_id}/{adapter_id}/` | `.safetensors` weights, config YAML | Indefinite |
| `familiar/evals/{familiar_id}/{run_id}/` | Eval-generated images + metadata JSON | Permanent delete at 90 days |
| `familiar/archive/{familiar_id}/` | Full archival bundles (`.zip` / `.tar`) | Indefinite |
| `familiar/personality/{familiar_id}/{version}/` | Personality card YAML exports | Indefinite |

### Lifecycle Rule Enforcement

Apply lifecycle policy to permanently delete eval artifacts under `familiar/evals/` after 90 days:

```bash
# Load credentials from .env
set -a && source .env && set +a

# Create the bucket if missing (using minio/mc container)
docker run --rm --network test_dbs_default \
  -e MC_HOST_local="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@minio:9000" \
  minio/mc mb --ignore-existing local/kimini

# Add lifecycle rule for eval artifacts
docker run --rm --network test_dbs_default \
  -e MC_HOST_local="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@minio:9000" \
  minio/mc ilm add --expire-days 90 --prefix "familiar/evals/" local/kimini

# Verify rules
docker run --rm --network test_dbs_default \
  -e MC_HOST_local="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@minio:9000" \
  minio/mc ilm ls local/kimini
```

Note: no tiering is configured in this stack; expiration is a permanent delete.

## Redis Validation Checklist

This section is documentation-only. Do not apply Redis config changes from this checklist.

### Database Index Assignments

- [ ] `DB 0` is used by application services in this stack.
- [ ] `kimini` task queues use `taskiq:*` key prefixes in `DB 0`.
- [ ] `gothmog` orchestration keys use `orcq:*` and `orcr:*` key prefixes in `DB 0`.
- [ ] If future isolation is needed, assign dedicated DB indexes per service and update this README.

### Key Naming Conventions

- [ ] Queue/list keys use descriptive namespaces (examples: `taskiq:gen:high`, `taskiq:gen:default`, `taskiq:gen:low`, `orcq:runs`).
- [ ] Run/result cache keys include stable IDs (example: `orcr:{run_id}`).
- [ ] New services must use a unique namespace prefix to avoid collisions.

### TTL Expectations

- [ ] Queue/work-dispatch keys generally have no TTL while active.
- [ ] Result/cache keys should set explicit TTLs only when data is safely reconstructable.
- [ ] If a service depends on expiration behavior, document the exact TTL and key pattern in this README.
