#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=chaos/scenarios/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

controller="${1:-kraft-controller-1}"
require_service_name "${controller}"

case "${controller}" in
  kraft-controller-1|kraft-controller-2|kraft-controller-3) ;;
  *) die "expected controller service kraft-controller-1, kraft-controller-2, or kraft-controller-3" ;;
esac

log "killing controller ${controller}"
run docker compose -f "${ROOT_DIR}/docker-compose.yml" --profile migration kill "${controller}"
log "waiting for quorum failover"
run sleep 15
log "restarting controller ${controller}"
run docker compose -f "${ROOT_DIR}/docker-compose.yml" --profile migration up -d --no-deps "${controller}"
verify_cluster
