#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRY_RUN="${DRY_RUN:-false}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-kafka-zk-kraft}"

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

die() {
  printf '[%s] ERROR: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
  exit 1
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

require_service_name() {
  local service="${1:-}"
  [[ -n "${service}" ]] || die "service name is required"
}

verify_cluster() {
  local args=()
  [[ "${DRY_RUN}" == "true" ]] && args+=(--dry-run --skip-live-checks)
  run "${ROOT_DIR}/scripts/verify.sh" "${args[@]}"
}
