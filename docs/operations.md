# Operations

## Health Signals

Monitor these during the full migration window:

- Broker availability and request latency.
- Under-replicated partitions.
- Offline partitions.
- ISR shrink and expand rates.
- Controller quorum leader and high watermark.
- ZooKeeper quorum health before finalization.
- Consumer lag for critical groups.
- Transaction abort and commit rates for exactly-once workloads.

## Common Commands

```bash
make compose-config
make kustomize-local
make kustomize-production
scripts/precheck.sh
scripts/verify.sh
```

## Paging Rules

Page for:

- Offline partitions.
- Any sustained under-replicated partitions during migration.
- Loss of KRaft controller quorum.
- Loss of ZooKeeper quorum before finalization.
- Sustained producer error rates on critical write paths.

Ticket for:

- Noncritical consumer lag.
- Single exporter failures when the Kafka service itself remains healthy.
- Dashboard or scrape gaps that do not affect incident response.

