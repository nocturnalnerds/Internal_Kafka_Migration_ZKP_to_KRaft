# Chaos Testing

Chaos scenarios validate that the migration topology handles failures without
losing data or violating replication guarantees.

Run scenarios only against disposable local or staging clusters:

```bash
DRY_RUN=true chaos/scenarios/kill-broker.sh kafka-2
chaos/scenarios/kill-broker.sh kafka-2
chaos/scenarios/controller-failover.sh kraft-controller-1
chaos/scenarios/zookeeper-failover.sh zookeeper-1
chaos/scenarios/network-isolate-broker.sh kafka-3 30
chaos/scenarios/disk-pressure.sh kafka-2 256
```

After each scenario:

```bash
scripts/verify.sh
```

Expected invariants:

- No under-replicated partitions after recovery.
- No offline partitions.
- Controller quorum elects a leader.
- Producers with `acks=all` continue or fail explicitly.
- Consumers with `read_committed` never observe aborted transactional records.

