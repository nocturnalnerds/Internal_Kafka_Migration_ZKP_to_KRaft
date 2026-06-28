# Production Checklist

## Before Migration

- Confirm all brokers run a Kafka version that supports ZooKeeper to KRaft migration.
- Confirm broker inter-version compatibility and client compatibility.
- Confirm every critical topic has replication factor 3 or an approved exception.
- Confirm `min.insync.replicas=2` for critical write paths.
- Confirm producers use `acks=all` for critical writes.
- Confirm there are no under-replicated or offline partitions.
- Export topics, configs, ACLs, SCRAM users, and consumer groups.
- Freeze nonessential topic/config changes during the migration window.
- Confirm rollback criteria, finalization criteria, and owner approvals.

## During Migration

- Start all three KRaft controllers.
- Roll one broker at a time.
- Verify broker health after each broker restart.
- Watch under-replicated partitions, offline partitions, request latency, ISR changes,
  controller leadership, and consumer lag.
- Keep client traffic synthetic checks running.

## Finalization

- Finalize only after metadata parity and client checks pass.
- Keep ZooKeeper running during the acceptance window.
- Do not destroy ZooKeeper data until recovery sign-off is complete.
- Update runbooks, dashboards, and paging rules to treat KRaft as the metadata plane.

## After Migration

- Remove ZooKeeper dependencies from broker deployment definitions.
- Validate ACL changes with representative clients.
- Re-run chaos scenarios against KRaft controllers and brokers.
- Archive migration snapshots and command transcripts.

