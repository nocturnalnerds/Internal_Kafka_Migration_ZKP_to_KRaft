# Disaster Recovery

## Recovery Artifacts

The pre-check and migration flow captures:

- Topic descriptions.
- Broker and topic configs.
- ACLs.
- Consumer group offsets.

Store production snapshots outside the cluster being migrated.

## Rollback Windows

Before finalization, rollback returns brokers to ZooKeeper mode and stops KRaft
controllers:

```bash
CONFIRM_ROLLBACK=yes scripts/rollback.sh
```

After finalization, rollback is a restore operation, not a simple restart. The
repository blocks post-finalization rollback unless
`ALLOW_POST_FINALIZE_ROLLBACK=true` is set to force an operator to acknowledge
that a tested restore plan is required.

## Restore Principles

- Restore the metadata plane and broker data as a consistent set.
- Prefer restoring into an isolated validation environment first.
- Do not point clients at a restored cluster until topic metadata, ACLs, and
  committed offsets are verified.
- Keep transactional producers fenced by preserving or intentionally rotating
  transactional IDs.

