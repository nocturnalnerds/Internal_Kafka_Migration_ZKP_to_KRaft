# Exactly-Once Semantics

Exactly-once semantics in Kafka requires three coordinated settings:

1. Idempotent producers with `acks=all`.
2. Transactional producers with a stable `transactional.id`.
3. Consumers reading committed data with `isolation.level=read_committed`.

The Java `ExactlyOnceProcessor` example consumes from `orders`, writes to
`payments`, and commits consumed offsets in the same transaction with
`sendOffsetsToTransaction`.

This means a restarted processor either:

- Reprocesses records whose transaction did not commit, or
- Skips records whose output and offsets committed atomically.

