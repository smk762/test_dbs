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
