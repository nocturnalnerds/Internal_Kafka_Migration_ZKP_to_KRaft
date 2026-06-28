# Migration Scripts

The migration scripts are written to be explicit, repeatable, and safe to rehearse.
Every entry point supports `--dry-run` and `--skip-live-checks`.

## Entry Points

- `scripts/precheck.sh`: validates the source cluster and writes a metadata snapshot.
- `scripts/migrate.sh`: starts KRaft controllers and rolls brokers with migration flags.
- `scripts/verify.sh`: verifies controller quorum, broker health, metadata, ACLs, and client traffic.
- `scripts/finalize.sh`: rolls brokers into final KRaft broker mode.
- `scripts/rollback.sh`: returns brokers to ZooKeeper mode before finalization.

## Safe Rehearsal

```bash
scripts/precheck.sh --dry-run --skip-live-checks
scripts/migrate.sh --dry-run --skip-live-checks
scripts/verify.sh --dry-run --skip-live-checks
CONFIRM_FINALIZE=yes scripts/finalize.sh --dry-run --skip-live-checks
CONFIRM_ROLLBACK=yes scripts/rollback.sh --dry-run --skip-live-checks
```

## Live Sequence

```bash
make compose-up
make create-topics
scripts/precheck.sh
scripts/migrate.sh
scripts/verify.sh
CONFIRM_FINALIZE=yes scripts/finalize.sh
```

Rollback before finalization:

```bash
CONFIRM_ROLLBACK=yes scripts/rollback.sh
```

Post-finalization rollback is intentionally blocked unless
`ALLOW_POST_FINALIZE_ROLLBACK=true` is set. A finalized rollback requires an
environment-specific restore plan because ZooKeeper metadata is no longer the
source of truth.

