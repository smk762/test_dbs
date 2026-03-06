# test_dbs

Docker Compose stack for quickly spinning up PostgreSQL, Redis, and MinIO (S3-compatible object storage) for development and testing.

## Services

| Service    | Image            | Default Port(s)   | Purpose                     |
|------------|------------------|--------------------|-----------------------------|
| PostgreSQL | `postgres:17`    | 5432               | Relational database         |
| Redis      | `redis:7`        | 6379               | In-memory key-value store   |
| MinIO      | `minio/minio`    | 9000 (API), 9001 (Console) | S3-compatible object storage |

## Quick Start

```bash
cp .env.example .env    # copy and edit credentials/ports as needed
docker compose up -d    # start all services
docker compose ps       # verify everything is healthy
```

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

## Management

```bash
docker compose logs -f          # tail all logs
docker compose down             # stop services (data persists in volumes)
docker compose down -v          # stop and destroy all data
docker compose up -d <service>  # start a single service (postgres, redis, minio)
```

Data is stored in Docker named volumes (`pgdata`, `redisdata`, `miniodata`) and survives `docker compose down` unless `-v` is passed.
