#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SECURITY_MODE="${SECURITY_MODE:-zookeeper}"
ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT:-zookeeper-1:2181,zookeeper-2:2181,zookeeper-3:2181/kafka}"
BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-1:9092}"

users=(
  "admin:admin-secret"
  "broker:broker-secret"
  "orders-producer:orders-producer-secret"
  "orders-consumer:orders-consumer-secret"
  "orders-retry-worker:orders-retry-worker-secret"
  "orders-outbox-worker:orders-outbox-worker-secret"
)

compose() {
  docker compose -f "${ROOT_DIR}/docker-compose.yml" "$@"
}

create_user_zookeeper() {
  local user="$1"
  local password="$2"
  compose exec -T kafka-1 kafka-configs \
    --zookeeper "${ZOOKEEPER_CONNECT}" \
    --alter \
    --add-config "SCRAM-SHA-512=[iterations=8192,password=${password}]" \
    --entity-type users \
    --entity-name "${user}"
}

create_user_kraft() {
  local user="$1"
  local password="$2"
  compose exec -T kafka-1 kafka-configs \
    --bootstrap-server "${BOOTSTRAP_SERVER}" \
    --alter \
    --add-config "SCRAM-SHA-512=[iterations=8192,password=${password}]" \
    --entity-type users \
    --entity-name "${user}"
}

for spec in "${users[@]}"; do
  IFS=":" read -r user password <<< "${spec}"
  printf 'Creating SCRAM user %s in %s mode\n' "${user}" "${SECURITY_MODE}"
  case "${SECURITY_MODE}" in
    zookeeper)
      create_user_zookeeper "${user}" "${password}"
      ;;
    kraft)
      create_user_kraft "${user}" "${password}"
      ;;
    *)
      printf 'Unknown SECURITY_MODE: %s\n' "${SECURITY_MODE}" >&2
      exit 1
      ;;
  esac
done

