#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/verify.sh [--dry-run] [--skip-live-checks]

Verifies broker health, controller quorum health, metadata visibility, ACL
readability, and a minimal produce/consume path.
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

if [[ "${DRY_RUN}" == "true" ]]; then
  log "dry-run: verify would check brokers, controllers, topics, ACLs, and client traffic"
  exit 0
fi

if [[ "${SKIP_LIVE_CHECKS}" == "true" ]]; then
  log "skip-live-checks: verification skipped"
  exit 0
fi

for broker in "${BROKERS[@]}"; do
  wait_for_compose_service "${broker}" 180
done

for controller in "${CONTROLLERS[@]}"; do
  wait_for_compose_service "${controller}" 180
done

log "checking metadata quorum status"
run controller_exec kraft-controller-1 kafka-metadata-quorum --bootstrap-controller "${CONTROLLER_BOOTSTRAP}" describe --status

log "checking topics and partition health"
run kafka_exec kafka-1 kafka-topics --bootstrap-server "${BOOTSTRAP_SERVER}" --describe

under_replicated="$(kafka_exec kafka-1 kafka-topics --bootstrap-server "${BOOTSTRAP_SERVER}" --describe --under-replicated-partitions)"
if [[ -n "${under_replicated}" ]]; then
  printf '%s\n' "${under_replicated}" >&2
  die "Under-replicated partitions detected"
fi

log "checking ACL readability"
run kafka_exec kafka-1 kafka-acls --bootstrap-server "${BOOTSTRAP_SERVER}" --list

health_topic="migration.healthcheck"
run kafka_exec kafka-1 kafka-topics --bootstrap-server "${BOOTSTRAP_SERVER}" --create --if-not-exists --topic "${health_topic}" --partitions 3 --replication-factor 3 --config min.insync.replicas=2

message="migration-check-$(date -u +%Y%m%dT%H%M%SZ)"
log "checking produce and consume path with ${health_topic}"
printf '%s\n' "${message}" | kafka_exec kafka-1 kafka-console-producer --bootstrap-server "${BOOTSTRAP_SERVER}" --topic "${health_topic}" >/dev/null
consumed="$(kafka_exec kafka-1 kafka-console-consumer --bootstrap-server "${BOOTSTRAP_SERVER}" --topic "${health_topic}" --from-beginning --timeout-ms 10000 --max-messages 1 || true)"
if [[ "${consumed}" != *"${message}"* ]]; then
  die "Failed to consume health-check message from ${health_topic}"
fi

mark_state verification-passed
log "verification completed"

