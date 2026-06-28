#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DRY_RUN="${DRY_RUN:-false}"
SKIP_LIVE_CHECKS="${SKIP_LIVE_CHECKS:-false}"
STATE_DIR="${STATE_DIR:-${ROOT_DIR}/.migration-state}"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"
BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-1:9092}"
CONTROLLER_BOOTSTRAP="${CONTROLLER_BOOTSTRAP:-kraft-controller-1:9093}"

BROKERS=(kafka-1 kafka-2 kafka-3)
ZOOKEEPERS=(zookeeper-1 zookeeper-2 zookeeper-3)
CONTROLLERS=(kraft-controller-1 kraft-controller-2 kraft-controller-3)

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
  exit 1
}

usage_common() {
  cat <<'EOF'
Common options:
  --dry-run            Print actions without executing cluster changes.
  --skip-live-checks   Skip Docker and Kafka health checks.
  -h, --help           Show help for the selected script.
EOF
}

parse_common_arg() {
  case "${1:-}" in
    --dry-run)
      DRY_RUN=true
      return 0
      ;;
    --skip-live-checks)
      SKIP_LIVE_CHECKS=true
      return 0
      ;;
    -h|--help)
      return 2
      ;;
    *)
      return 1
      ;;
  esac
}

require_command() {
  local command_name="$1"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "dry-run: would require command ${command_name}"
    return 0
  fi
  command -v "${command_name}" >/dev/null 2>&1 || die "Required command not found: ${command_name}"
}

run() {
  log "+ $*"
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  "$@"
}

compose() {
  docker compose -f "${ROOT_DIR}/docker-compose.yml" "$@"
}

compose_migration() {
  docker compose \
    -f "${ROOT_DIR}/docker-compose.yml" \
    -f "${ROOT_DIR}/docker-compose.migration.yml" \
    "$@"
}

compose_kraft() {
  docker compose \
    -f "${ROOT_DIR}/docker-compose.yml" \
    -f "${ROOT_DIR}/docker-compose.kraft.yml" \
    "$@"
}

compose_with_profile() {
  local profile="$1"
  shift
  docker compose -f "${ROOT_DIR}/docker-compose.yml" --profile "${profile}" "$@"
}

ensure_state_dir() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "dry-run: would create ${STATE_DIR}"
    return 0
  fi
  mkdir -p "${STATE_DIR}"
}

mark_state() {
  local marker="$1"
  ensure_state_dir
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "dry-run: would mark state ${marker}"
    return 0
  fi
  date -u +%Y-%m-%dT%H:%M:%SZ > "${STATE_DIR}/${marker}"
}

state_exists() {
  [[ -f "${STATE_DIR}/${1}" ]]
}

wait_for_compose_service() {
  local service="$1"
  local timeout_seconds="${2:-180}"
  local start
  start="$(date +%s)"

  if [[ "${DRY_RUN}" == "true" || "${SKIP_LIVE_CHECKS}" == "true" ]]; then
    log "dry-run/skip: would wait for ${service} to become healthy"
    return 0
  fi

  while true; do
    local status
    status="$(compose ps --format json "${service}" 2>/dev/null | python3 -c 'import json,sys; data=sys.stdin.read().strip(); print(json.loads(data).get("Health", "")) if data else print("")')"
    if [[ "${status}" == "healthy" ]]; then
      log "${service} is healthy"
      return 0
    fi

    if (( $(date +%s) - start > timeout_seconds )); then
      die "Timed out waiting for ${service}; last health status: ${status:-unknown}"
    fi
    sleep 5
  done
}

kafka_exec() {
  local service="$1"
  shift
  compose exec -T "${service}" "$@"
}

controller_exec() {
  local service="$1"
  shift
  compose_with_profile migration exec -T "${service}" "$@"
}

snapshot_metadata() {
  local snapshot_dir="${BACKUP_DIR}/$(date -u +%Y%m%dT%H%M%SZ)"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "dry-run: would snapshot metadata into ${snapshot_dir}"
    return 0
  fi

  mkdir -p "${snapshot_dir}"
  kafka_exec kafka-1 kafka-topics --bootstrap-server "${BOOTSTRAP_SERVER}" --describe > "${snapshot_dir}/topics.txt"
  kafka_exec kafka-1 kafka-configs --bootstrap-server "${BOOTSTRAP_SERVER}" --all --describe > "${snapshot_dir}/configs.txt"
  kafka_exec kafka-1 kafka-acls --bootstrap-server "${BOOTSTRAP_SERVER}" --list > "${snapshot_dir}/acls.txt" || true
  kafka_exec kafka-1 kafka-consumer-groups --bootstrap-server "${BOOTSTRAP_SERVER}" --all-groups --describe > "${snapshot_dir}/consumer-groups.txt" || true
  log "metadata snapshot written to ${snapshot_dir}"
}

assert_not_finalized() {
  if state_exists finalized && [[ "${ALLOW_POST_FINALIZE_ROLLBACK:-false}" != "true" ]]; then
    die "Cluster is marked finalized. Set ALLOW_POST_FINALIZE_ROLLBACK=true only if you have a tested restore plan."
  fi
}

