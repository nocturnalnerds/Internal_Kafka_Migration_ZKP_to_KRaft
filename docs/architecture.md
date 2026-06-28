# Architecture

This document describes the repository target state and migration phases.

## Target Components

```mermaid
flowchart LR
  subgraph ZK["Initial ZooKeeper Metadata Plane"]
    zk1["ZooKeeper 1"]
    zk2["ZooKeeper 2"]
    zk3["ZooKeeper 3"]
  end

  subgraph Brokers["Kafka Data Plane"]
    b1["Broker 1"]
    b2["Broker 2"]
    b3["Broker 3"]
  end

  subgraph KRaft["Dedicated KRaft Controller Quorum"]
    c1["Controller 1"]
    c2["Controller 2"]
    c3["Controller 3"]
  end

  subgraph Obs["Observability"]
    prom["Prometheus"]
    graf["Grafana"]
    am["Alertmanager"]
  end

  ZK --> Brokers
  ZK -. "metadata migration" .-> KRaft
  KRaft --> Brokers
  Brokers --> Obs
  KRaft --> Obs
```

## Migration Phases

1. Pre-check the ZooKeeper cluster, brokers, topics, ACLs, consumer groups, and
   client compatibility.
2. Start the dedicated KRaft controllers in migration mode.
3. Roll the brokers with migration-aware configuration.
4. Verify metadata parity, client traffic, replication health, and ACL behavior.
5. Finalize the brokers in KRaft mode and remove ZooKeeper dependencies.
6. Keep rollback artifacts until the post-migration acceptance window closes.

Each phase has a script and a documented runbook.

## Kubernetes Topology

The Kubernetes deployment uses StatefulSets and headless services so each
ZooKeeper node, broker, and controller keeps stable network identity and durable
storage.

```mermaid
flowchart TB
  subgraph ns["Namespace: kafka-migration"]
    zk["zookeeper StatefulSet x3"]
    brokers["kafka StatefulSet x3"]
    controllers["kraft-controller StatefulSet x3"]
    svc["kafka-bootstrap Service"]
  end

  svc --> brokers
  brokers -. "pre-finalization" .-> zk
  controllers -. "migration" .-> zk
  brokers --> controllers
```
