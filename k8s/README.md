# Kubernetes Deployment

Kubernetes manifests are managed with Kustomize.

## Layout

- `base`: migration-capable topology with ZooKeeper, Kafka brokers, and KRaft controllers.
- `overlays/local`: lower resource requests for local clusters.
- `overlays/production`: production resource sizing and anti-affinity.
- `overlays/final-kraft`: broker configuration after KRaft finalization.
- `overlays/secure`: TLS/SASL/SCRAM/ACL-oriented broker configuration.

## Validate

```bash
kubectl kustomize k8s/overlays/local
kubectl kustomize k8s/overlays/final-kraft
kubectl kustomize k8s/overlays/production
kubectl kustomize k8s/overlays/secure
```

## Deploy Local Overlay

```bash
kubectl apply -k k8s/overlays/local
```

## Migration Flow

1. Deploy `k8s/overlays/local` or `k8s/overlays/production`.
2. Run the pre-check job or equivalent operational checks.
3. Roll brokers with `zookeeper.metadata.migration.enable=true`.
4. Verify metadata and client traffic.
5. Apply `k8s/overlays/final-kraft` after approval.
