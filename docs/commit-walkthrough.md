# Commit Walkthrough

The repository is built as logical, buildable commits:

1. `Initialize migration lab scaffold`
   - Baseline README, architecture note, Makefile, and stdlib tests.
2. `Add local ZooKeeper Kafka and KRaft compose stack`
   - Docker Compose topology with 3 ZooKeeper nodes, 3 ZooKeeper-mode brokers,
     3 KRaft controllers, persistence, health checks, and topic bootstrap.
3. `Add migration orchestration scripts`
   - Pre-check, migration, verification, finalization, rollback, dry-run support,
     and migration runbook.
4. `Add Kubernetes StatefulSet deployment manifests`
   - Kustomize base and overlays with StatefulSets, PVCs, services, probes, and PDBs.
5. `Add observability and security configuration`
   - Prometheus, Grafana, Alertmanager, JMX Exporter configs, TLS, SCRAM, ACLs,
     and secure overlays.
6. `Add messaging pattern application examples`
   - Go and Java examples for producers, consumers, idempotence, transactions,
     exactly-once processing, outbox, retries, and DLQ.
7. `Add chaos testing CI and operations docs`
   - Chaos scenarios, GitHub Actions, production checklists, and operating docs.

