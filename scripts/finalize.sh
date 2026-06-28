#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

CONFIRM_FINALIZE="${CONFIRM_FINALIZE:-no}"
STOP_ZOOKEEPER_AFTER_FINALIZE="${STOP_ZOOKEEPER_AFTER_FINALIZE:-false}"

usage() {
  cat <<'EOF'
Usage: CONFIRM_FINALIZE=yes scripts/finalize.sh [--dry-run] [--skip-live-checks]

Rolls brokers into KRaft broker mode using docker-compose.kraft.yml. ZooKeeper is
left running by default until the post-migration acceptance window closes.
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

if [[ "${DRY_RUN}" != "true" && "${CONFIRM_FINALIZE}" != "yes" ]]; then
  die "Set CONFIRM_FINALIZE=yes to finalize the migration"
fi

forward_args=()
[[ "${DRY_RUN}" == "true" ]] && forward_args+=(--dry-run)
[[ "${SKIP_LIVE_CHECKS}" == "true" ]] && forward_args+=(--skip-live-checks)

run "${ROOT_DIR}/scripts/verify.sh" "${forward_args[@]}"

log "rolling brokers into final KRaft broker mode"
for broker in "${BROKERS[@]}"; do
  run compose_kraft up -d --no-deps --force-recreate "${broker}"
  wait_for_compose_service "${broker}" 240
done

run "${ROOT_DIR}/scripts/verify.sh" "${forward_args[@]}"

if [[ "${STOP_ZOOKEEPER_AFTER_FINALIZE}" == "true" ]]; then
  log "stopping ZooKeeper ensemble after finalization"
  run compose_kraft stop "${ZOOKEEPERS[@]}"
else
  warn "ZooKeeper left running. Stop it after the acceptance window with STOP_ZOOKEEPER_AFTER_FINALIZE=true."
fi

mark_state finalized
log "finalization completed"
