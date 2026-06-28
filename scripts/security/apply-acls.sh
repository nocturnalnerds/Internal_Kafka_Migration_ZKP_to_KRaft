#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-1:9092}"
ADMIN_CONFIG="${ADMIN_CONFIG:-/opt/kafka-lab/security/client-admin-container.properties}"

compose() {
  docker compose \
    -f "${ROOT_DIR}/docker-compose.yml" \
    -f "${ROOT_DIR}/docker-compose.secure.yml" \
    "$@"
}

kafka_acls() {
  compose exec -T kafka-1 kafka-acls \
    --bootstrap-server "${BOOTSTRAP_SERVER}" \
    --command-config "${ADMIN_CONFIG}" \
    "$@"
}

kafka_acls --add --allow-principal User:orders-producer --operation Write --operation Describe --topic orders
kafka_acls --add --allow-principal User:orders-producer --operation Write --operation Describe --topic payments
kafka_acls --add --allow-principal User:orders-consumer --operation Read --operation Describe --topic orders --group orders-consumer
kafka_acls --add --allow-principal User:orders-retry-worker --operation Read --operation Write --operation Describe --topic orders --topic orders.retry.0 --topic orders.retry.1 --topic orders.dlq --group orders-retry-worker
kafka_acls --add --allow-principal User:orders-outbox-worker --operation Read --operation Write --operation Describe --topic orders.outbox --topic orders --group orders-outbox-worker
kafka_acls --list
