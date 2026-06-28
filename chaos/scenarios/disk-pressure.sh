#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=chaos/scenarios/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

broker="${1:-kafka-1}"
megabytes="${2:-256}"

case "${broker}" in
  kafka-1|kafka-2|kafka-3) ;;
  *) die "expected broker service kafka-1, kafka-2, or kafka-3" ;;
esac

log "creating ${megabytes}MiB pressure file on ${broker}"
run compose exec -T "${broker}" bash -ec "dd if=/dev/zero of=/var/lib/kafka/data/chaos-pressure.bin bs=1M count=${megabytes}"
verify_cluster
log "removing pressure file on ${broker}"
run compose exec -T "${broker}" rm -f /var/lib/kafka/data/chaos-pressure.bin
