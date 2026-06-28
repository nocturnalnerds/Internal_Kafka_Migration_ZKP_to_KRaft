#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

CONFIRM_ROLLBACK="${CONFIRM_ROLLBACK:-no}"

usage() {
  cat <<'EOF'
Usage: CONFIRM_ROLLBACK=yes scripts/rollback.sh [--dry-run] [--skip-live-checks]

Returns brokers to the base ZooKeeper-mode Compose configuration and stops the
KRaft controllers. This rollback is intended before finalization.
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

assert_not_finalized
require_command docker

if [[ "${DRY_RUN}" != "true" && "${CONFIRM_ROLLBACK}" != "yes" ]]; then
  die "Set CONFIRM_ROLLBACK=yes to roll back the migration"
fi

forward_args=()
[[ "${DRY_RUN}" == "true" ]] && forward_args+=(--dry-run)
[[ "${SKIP_LIVE_CHECKS}" == "true" ]] && forward_args+=(--skip-live-checks)

log "rolling brokers back to ZooKeeper-mode configuration"
for broker in "${BROKERS[@]}"; do
  run compose up -d --no-deps --force-recreate "${broker}"
  wait_for_compose_service "${broker}" 240
done

log "stopping KRaft controllers"
run compose_with_profile migration stop "${CONTROLLERS[@]}"

run "${ROOT_DIR}/scripts/verify.sh" "${forward_args[@]}"
mark_state rollback-completed
log "rollback completed"
