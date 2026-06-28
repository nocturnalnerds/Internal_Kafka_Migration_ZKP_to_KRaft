#!/usr/bin/env bash
set -Eeuo pipefail

BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-1:9092}"
CLIENT_CONFIG="${CLIENT_CONFIG:-/opt/kafka-lab/client.properties}"

topics=(
  "orders:6:3"
  "orders.retry.0:6:3"
  "orders.retry.1:6:3"
  "orders.dlq:6:3"
  "orders.outbox:6:3"
  "payments:6:3"
  "inventory.adjustments:6:3"
)

for topic_spec in "${topics[@]}"; do
  IFS=":" read -r topic partitions replication <<< "${topic_spec}"
  kafka-topics \
    --bootstrap-server "${BOOTSTRAP_SERVER}" \
    --command-config "${CLIENT_CONFIG}" \
    --create \
    --if-not-exists \
    --topic "${topic}" \
    --partitions "${partitions}" \
    --replication-factor "${replication}" \
    --config min.insync.replicas=2
done

kafka-topics \
  --bootstrap-server "${BOOTSTRAP_SERVER}" \
  --command-config "${CLIENT_CONFIG}" \
  --list

