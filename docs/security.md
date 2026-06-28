# Security Model

The lab demonstrates Kafka security with TLS, SASL/SCRAM, and ACLs.

## TLS

`scripts/security/generate-certs.sh` creates a local CA, broker keystores, a
shared truststore, and client certificates. Generated material is intentionally
ignored by git.

## SASL/SCRAM

`scripts/security/create-scram-users.sh` creates users for:

- `admin`
- `broker`
- `orders-producer`
- `orders-consumer`
- `orders-retry-worker`
- `orders-outbox-worker`

ZooKeeper mode uses `kafka-configs --zookeeper`. KRaft mode uses
`kafka-configs --bootstrap-server`.

## ACLs

`scripts/security/apply-acls.sh` grants minimum topic and group permissions for
the sample applications. The secure overlay sets
`allow.everyone.if.no.acl.found=false` so missing ACLs fail closed.

## Kubernetes

The `k8s/overlays/secure` overlay shows how to mount a `kafka-tls` secret and
switch brokers to `SASL_SSL`. Create the secret from generated keystores before
applying the overlay.

