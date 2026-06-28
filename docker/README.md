# Docker Compose

The default Compose profile starts the source Kafka cluster:

- 3 ZooKeeper nodes.
- 3 Kafka brokers in ZooKeeper mode.
- Persistent Docker volumes for all quorum and broker data.
- Broker and ZooKeeper health checks.

Start the source cluster:

```bash
cp .env.example .env
docker compose up -d zookeeper-1 zookeeper-2 zookeeper-3 kafka-1 kafka-2 kafka-3
docker compose --profile tools run --rm kafka-init
```

Start dedicated KRaft controllers for migration work:

```bash
docker compose --profile migration up -d kraft-controller-1 kraft-controller-2 kraft-controller-3
```

The migration scripts introduced later orchestrate controller formatting,
controller startup, broker rolling restarts, verification, finalization, and
rollback.

