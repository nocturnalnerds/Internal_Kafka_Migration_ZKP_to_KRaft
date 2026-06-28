# Retry Topics And DLQ

The retry worker demonstrates a simple topic-based failure path:

- `orders`
- `orders.retry.0`
- `orders.retry.1`
- `orders.dlq`

Failed records are republished with headers:

- `x-original-topic`
- `x-retry-attempt`
- `x-available-at`

In production, delay enforcement is normally handled by a scheduler, stream
processor, or worker that only releases messages when `x-available-at` has
passed. The example keeps delay metadata explicit and testable.

