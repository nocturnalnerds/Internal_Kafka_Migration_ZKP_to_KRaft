# ZooKeeper to KRaft Migration Runbook

This runbook describes the local lab flow and the operational controls expected
in a production migration.

## Pre-Migration Gate

1. Confirm all brokers and ZooKeeper nodes are healthy.
2. Confirm there are no under-replicated partitions.
3. Confirm all topics have replication factor 3 and `min.insync.replicas=2`
   unless a documented exception exists.
4. Confirm clients support the broker version and security configuration.
5. Capture topics, broker configs, ACLs, and consumer group offsets.

Command:

```bash
scripts/precheck.sh
```

## Migration Phase

The migration phase starts the dedicated KRaft controller quorum, then rolls the
brokers with migration-aware configuration. Client traffic continues to use the
brokers during this phase.

```bash
scripts/migrate.sh
scripts/verify.sh
```

Acceptance checks:

- Controller quorum reports a leader and current high watermark.
- Brokers remain healthy after each rolling restart.
- Topic descriptions match the pre-migration snapshot.
- ACL listing remains readable.
- Produce and consume health checks pass.

## Finalization

Finalization changes the brokers to KRaft broker mode. ZooKeeper is left running
by default for a short acceptance window, but is no longer the metadata source of
truth.

```bash
CONFIRM_FINALIZE=yes scripts/finalize.sh
```

Stop ZooKeeper after the acceptance window:

```bash
STOP_ZOOKEEPER_AFTER_FINALIZE=true CONFIRM_FINALIZE=yes scripts/finalize.sh
```

## Rollback

Rollback is intended before finalization:

```bash
CONFIRM_ROLLBACK=yes scripts/rollback.sh
```

After finalization, rollback requires restoring from validated backups and is
therefore blocked unless `ALLOW_POST_FINALIZE_ROLLBACK=true` is set.

