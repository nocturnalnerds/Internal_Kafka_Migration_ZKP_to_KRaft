#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/migrate.sh [--dry-run] [--skip-live-checks]

Starts dedicated KRaft controllers in migration mode and rolls ZooKeeper-mode
brokers with migration-aware configuration.
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

forward_args=()
[[ "${DRY_RUN}" == "true" ]] && forward_args+=(--dry-run)
[[ "${SKIP_LIVE_CHECKS}" == "true" ]] && forward_args+=(--skip-live-checks)

run "${ROOT_DIR}/scripts/precheck.sh" "${forward_args[@]}"

log "starting dedicated KRaft controllers in migration profile"
run compose_with_profile migration up -d "${CONTROLLERS[@]}"

for controller in "${CONTROLLERS[@]}"; do
  wait_for_compose_service "${controller}" 240
done

log "rolling brokers with ZooKeeper to KRaft migration flags"
for broker in "${BROKERS[@]}"; do
  run compose_migration up -d --no-deps --force-recreate "${broker}"
  wait_for_compose_service "${broker}" 240
done

run "${ROOT_DIR}/scripts/verify.sh" "${forward_args[@]}"
mark_state migration-started
log "migration phase completed; run scripts/finalize.sh after acceptance checks pass"
