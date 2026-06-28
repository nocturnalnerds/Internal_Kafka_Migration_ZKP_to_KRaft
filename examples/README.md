# Application Examples

The examples cover the client behaviors that matter during and after a
ZooKeeper to KRaft migration:

- Go producer and consumer.
- Go idempotent producer.
- Go retry worker with retry topics and DLQ.
- Go transactional outbox worker.
- Java transactional producer.
- Java exactly-once processor with `read_committed` consumption and transactional offset commits.

## Go

```bash
cd examples/go
go run ./cmd/producer
go run ./cmd/consumer
go run ./cmd/idempotent-producer
go run ./cmd/outbox-enqueue
go run ./cmd/outbox-worker
go run ./cmd/retry-worker
```

Common environment variables:

```text
KAFKA_BROKERS=localhost:19092,localhost:19093,localhost:19094
KAFKA_TOPIC=orders
KAFKA_GROUP_ID=orders-consumer
```

## Java

```bash
cd examples/java
mvn -q package
java -cp target/kafka-java-examples-1.0.0.jar com.example.kafka.tx.TransactionalProducer
java -cp target/kafka-java-examples-1.0.0.jar com.example.kafka.eos.ExactlyOnceProcessor
```

