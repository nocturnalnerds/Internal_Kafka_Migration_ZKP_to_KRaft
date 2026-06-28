#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=chaos/scenarios/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

broker="${1:-kafka-1}"
require_service_name "${broker}"

case "${broker}" in
  kafka-1|kafka-2|kafka-3) ;;
  *) die "expected broker service kafka-1, kafka-2, or kafka-3" ;;
esac

log "killing broker ${broker}"
run compose kill "${broker}"
log "restarting broker ${broker}"
run compose up -d --no-deps "${broker}"
verify_cluster
