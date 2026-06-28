# Transactional Outbox Pattern

The transactional outbox pattern keeps application state changes and outbound
events in the same database transaction. A separate worker reads unpublished
outbox rows and writes them to Kafka with an idempotent producer.

The Go example uses a JSONL file to keep the local demo dependency-free, but the
production shape is the same:

1. Write domain state and an outbox row in one database transaction.
2. Poll unpublished outbox rows.
3. Publish each event to Kafka with stable keys and idempotence enabled.
4. Mark the outbox row published after Kafka acknowledges the write.
5. Re-run safely because duplicate publishes keep the same event identity and key.

Example commands:

```bash
cd examples/go
go run ./cmd/outbox-enqueue
go run ./cmd/outbox-worker
```

