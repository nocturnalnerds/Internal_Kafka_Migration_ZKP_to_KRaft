# Kafka ZooKeeper to KRaft Migration Lab

This repository demonstrates extensive reasearch on uninternalized Kafka migration path from a ZooKeeper-managed cluster to KRaft with example of dedicated controllers.

The lab is intentionally layered:

1. Local development runs with Docker Compose for Testing.
2. Deployment manifests use Kubernetes StatefulSets managed by Kustomize.
3. Operational scripts perform pre-checks, migration, verification, finalization, and rollback.
4. Observability, security, sample clients, chaos testing, and CI are included as first-class repository concerns.

## Quick Commands

```bash
make test
make lint
make compose-config
```

More commands are added alongside the Compose, Kubernetes, and application layers.

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

## Kubernetes

```bash
kubectl kustomize k8s/overlays/local
kubectl apply -k k8s/overlays/local
```

The Kubernetes layer uses StatefulSets with persistent volume claim templates
for ZooKeeper, Kafka brokers, and dedicated KRaft controllers. See
[k8s/README.md](k8s/README.md).

## Observability And Security

```bash
make observability-up
scripts/security/generate-certs.sh
scripts/security/create-scram-users.sh
scripts/security/apply-acls.sh
```

See [observability/README.md](observability/README.md) and
[docs/security.md](docs/security.md).

## Application Examples

Go examples cover producers, consumers, idempotent producer settings, retry
topics, DLQ routing, and transactional outbox mechanics. Java examples cover the
Kafka transaction APIs used for transactional producers and exactly-once
processing.

See [examples/README.md](examples/README.md) and [docs/patterns](docs/patterns).

## Chaos And CI

Chaos scenarios live in [chaos](chaos) and **should be run only against local or
staging clusters**:

```bash
DRY_RUN=true chaos/scenarios/kill-broker.sh kafka-2
```

GitHub Actions validates repository tests, Docker Compose rendering, Kustomize
rendering, Go examples, Java examples, and shell scripts. See
[.github/workflows/ci.yml](.github/workflows/ci.yml).

## Operations Documentation

- [Local development](docs/local-development.md)
- [Production checklist](docs/production-checklist.md)
- [Operations](docs/operations.md)
- [Disaster recovery](docs/disaster-recovery.md)
- [Commit walkthrough](docs/commit-walkthrough.md)

## Architecture

The target topology is:

- 3 ZooKeeper nodes for the initial cluster metadata quorum.
- 3 Kafka brokers initially running in ZooKeeper mode.
- 3 dedicated KRaft controllers introduced during migration.
- Kafka brokers finalized into KRaft broker mode after metadata migration.
- Prometheus, Grafana, Alertmanager, and JMX Exporter for observability (Local Only).
- TLS, SASL/SCRAM, and ACLs for secure access.

See [docs/architecture.md](docs/architecture.md) for the evolving design.

## Development Requirements

- Bash 4+
- Python 3.10+
- Docker with the Compose plugin
- kubectl and kustomize for Kubernetes workflows
- Go 1.22+ for sample clients

Only Python and Bash are required for the baseline repository tests.
