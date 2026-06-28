# Kafka ZooKeeper to KRaft Migration Lab

This repository demonstrates a production-grade Kafka migration path from a
ZooKeeper-managed cluster to KRaft with dedicated controllers.

The lab is intentionally layered:

1. Local development runs with Docker Compose.
2. Deployment manifests use Kubernetes StatefulSets managed by Kustomize.
3. Operational scripts perform pre-checks, migration, verification,
   finalization, and rollback.
4. Observability, security, sample clients, chaos testing, and CI are included
   as first-class repository concerns.

## Repository Status

The project is generated as incremental, buildable commits. Use the git log to
inspect each logical layer:

```bash
git log --oneline --decorate
```

## Quick Commands

```bash
make test
make lint
make compose-config
```

More commands are added alongside the Compose, Kubernetes, and application
layers.

## Local Migration Flow

```bash
cp .env.example .env
make compose-up
make create-topics
scripts/precheck.sh
scripts/migrate.sh
scripts/verify.sh
CONFIRM_FINALIZE=yes scripts/finalize.sh
```

See [docs/runbooks/migration.md](docs/runbooks/migration.md) for the full
runbook, rollback guidance, and acceptance checks.

## Architecture

The target topology is:

- 3 ZooKeeper nodes for the initial cluster metadata quorum.
- 3 Kafka brokers initially running in ZooKeeper mode.
- 3 dedicated KRaft controllers introduced during migration.
- Kafka brokers finalized into KRaft broker mode after metadata migration.
- Prometheus, Grafana, Alertmanager, and JMX Exporter for observability.
- TLS, SASL/SCRAM, and ACLs for secure access.

See [docs/architecture.md](docs/architecture.md) for the evolving design.

## Development Requirements

- Bash 4+
- Python 3.10+
- Docker with the Compose plugin
- kubectl and kustomize for Kubernetes workflows
- Go 1.22+ for sample clients

Only Python and Bash are required for the baseline repository tests.
