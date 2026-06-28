# Local Development

## Start The Source Cluster

```bash
cp .env.example .env
make compose-up
make create-topics
```

## Add Observability

```bash
make observability-up
```

## Rehearse Migration

```bash
scripts/precheck.sh --dry-run --skip-live-checks
scripts/migrate.sh --dry-run --skip-live-checks
scripts/verify.sh --dry-run --skip-live-checks
CONFIRM_FINALIZE=yes scripts/finalize.sh --dry-run --skip-live-checks
```

## Run Clients

```bash
cd examples/go
go run ./cmd/producer
go run ./cmd/consumer
```

## Stop

```bash
make compose-down
```

Persistent Docker volumes are kept by default. Remove them only when you want a
fresh lab environment:

```bash
docker compose down -v
```

