#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck source=chaos/scenarios/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

node="${1:-zookeeper-1}"
require_service_name "${node}"

case "${node}" in
  zookeeper-1|zookeeper-2|zookeeper-3) ;;
  *) die "expected ZooKeeper service zookeeper-1, zookeeper-2, or zookeeper-3" ;;
esac

log "stopping ZooKeeper node ${node}"
run compose stop "${node}"
log "checking brokers while ZooKeeper quorum remains available"
verify_cluster
log "restarting ZooKeeper node ${node}"
run compose up -d --no-deps "${node}"
