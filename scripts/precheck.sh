#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/precheck.sh [--dry-run] [--skip-live-checks]

Validates that the ZooKeeper-mode source cluster is ready for KRaft metadata
migration and captures a metadata snapshot.
EOF
  usage_common
}

for arg in "$@"; do
  if parse_common_arg "${arg}"; then
    continue
  elif [[ $? -eq 2 ]]; then
    usage
    exit 0
  else
    die "Unknown argument: ${arg}"
  fi
done

require_command docker
require_command python3

if [[ "${DRY_RUN}" == "true" ]]; then
  log "dry-run: precheck would validate Compose syntax and cluster health"
  exit 0
fi

run compose config --quiet

if [[ "${SKIP_LIVE_CHECKS}" == "true" ]]; then
  log "skip-live-checks: Compose syntax validated; live checks skipped"
  exit 0
fi

for service in "${ZOOKEEPERS[@]}" "${BROKERS[@]}"; do
  wait_for_compose_service "${service}" 180
done

log "checking broker API availability"
run kafka_exec kafka-1 kafka-broker-api-versions --bootstrap-server "${BOOTSTRAP_SERVER}"

log "checking for under-replicated partitions"
under_replicated="$(kafka_exec kafka-1 kafka-topics --bootstrap-server "${BOOTSTRAP_SERVER}" --describe --under-replicated-partitions)"
if [[ -n "${under_replicated}" ]]; then
  printf '%s\n' "${under_replicated}" >&2
  die "Under-replicated partitions must be fixed before migration"
fi

log "checking ZooKeeper broker registration"
run compose exec -T zookeeper-1 zookeeper-shell zookeeper-1:2181 ls /kafka/brokers/ids

snapshot_metadata
mark_state precheck-passed
log "precheck completed"

