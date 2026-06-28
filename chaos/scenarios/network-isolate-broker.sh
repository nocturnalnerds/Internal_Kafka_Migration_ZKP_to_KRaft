#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=chaos/scenarios/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

broker="${1:-kafka-1}"
duration="${2:-30}"
network="${COMPOSE_PROJECT_NAME}_kafka-net"

case "${broker}" in
  kafka-1|kafka-2|kafka-3) ;;
  *) die "expected broker service kafka-1, kafka-2, or kafka-3" ;;
esac

log "disconnecting ${broker} from ${network} for ${duration}s"
run docker network disconnect "${network}" "${broker}"
run sleep "${duration}"
log "reconnecting ${broker} to ${network}"
run docker network connect "${network}" "${broker}"
verify_cluster
