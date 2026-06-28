# Observability

The observability stack includes:

- Prometheus for metrics collection.
- JMX Exporter for Kafka, KRaft controllers, and ZooKeeper JVM metrics.
- Grafana with a provisioned Kafka overview dashboard.
- Alertmanager with local routing.

Start it with the local cluster:

```bash
make compose-up
make observability-up
```

Endpoints:

- Prometheus: <http://localhost:9090>
- Grafana: <http://localhost:3000>
- Alertmanager: <http://localhost:9093>

Default Grafana credentials come from `.env`:

```text
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

