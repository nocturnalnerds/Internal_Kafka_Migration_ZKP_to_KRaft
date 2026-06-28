# Security

The repository includes a local security workflow for:

- TLS certificates and Java keystores.
- SASL/SCRAM users.
- Kafka ACLs.
- Secure client properties.

## Local TLS

Generate a local certificate authority, broker certificates, and client
certificates:

```bash
scripts/security/generate-certs.sh
```

Generated files are written to `security/certs/generated/` and are ignored by
git.

## SCRAM Users

Create SCRAM users in ZooKeeper mode:

```bash
scripts/security/create-scram-users.sh
```

Create SCRAM users after KRaft finalization:

```bash
SECURITY_MODE=kraft scripts/security/create-scram-users.sh
```

## ACLs

Apply application ACLs:

```bash
scripts/security/apply-acls.sh
```

## Secure Compose

Start the secure overlay after generating certificates and SCRAM users:

```bash
docker compose -f docker-compose.yml -f docker-compose.secure.yml up -d kafka-1 kafka-2 kafka-3
```

This overlay uses `SASL_SSL` for internal and external listeners and disables
implicit authorization with `allow.everyone.if.no.acl.found=false`.

