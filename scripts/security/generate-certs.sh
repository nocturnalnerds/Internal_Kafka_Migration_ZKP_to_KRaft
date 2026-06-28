#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/security/certs/generated}"
PASSWORD="${PASSWORD:-changeit}"
DAYS="${DAYS:-825}"

BROKERS=(kafka-1 kafka-2 kafka-3)
CLIENTS=(admin orders-producer orders-consumer)

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Required command not found: %s\n' "$1" >&2
    exit 1
  }
}

write_credential_files() {
  printf '%s\n' "${PASSWORD}" > "${OUT_DIR}/keystore.creds"
  printf '%s\n' "${PASSWORD}" > "${OUT_DIR}/truststore.creds"
  printf '%s\n' "${PASSWORD}" > "${OUT_DIR}/key.creds"
}

generate_ca() {
  if [[ -f "${OUT_DIR}/ca.key" && -f "${OUT_DIR}/ca.crt" ]]; then
    printf 'CA already exists in %s\n' "${OUT_DIR}"
    return
  fi

  openssl req -new -x509 -nodes \
    -newkey rsa:4096 \
    -days "${DAYS}" \
    -keyout "${OUT_DIR}/ca.key" \
    -out "${OUT_DIR}/ca.crt" \
    -subj "/CN=kafka-migration-local-ca"
}

create_broker_keystore() {
  local broker="$1"
  local san="DNS:${broker},DNS:localhost,IP:127.0.0.1"

  if [[ -f "${OUT_DIR}/${broker}.keystore.jks" ]]; then
    printf 'Broker keystore already exists: %s\n' "${OUT_DIR}/${broker}.keystore.jks"
    return
  fi

  keytool -genkeypair \
    -alias "${broker}" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "${DAYS}" \
    -keystore "${OUT_DIR}/${broker}.keystore.jks" \
    -storepass "${PASSWORD}" \
    -keypass "${PASSWORD}" \
    -dname "CN=${broker},OU=Kafka,O=MigrationLab,L=Local,ST=Local,C=US" \
    -ext "SAN=${san}"

  keytool -certreq \
    -alias "${broker}" \
    -keystore "${OUT_DIR}/${broker}.keystore.jks" \
    -storepass "${PASSWORD}" \
    -file "${OUT_DIR}/${broker}.csr" \
    -ext "SAN=${san}"

  openssl x509 -req \
    -in "${OUT_DIR}/${broker}.csr" \
    -CA "${OUT_DIR}/ca.crt" \
    -CAkey "${OUT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${OUT_DIR}/${broker}.crt" \
    -days "${DAYS}" \
    -sha256 \
    -extfile <(printf 'subjectAltName=%s\n' "${san}")

  keytool -importcert \
    -noprompt \
    -alias CARoot \
    -file "${OUT_DIR}/ca.crt" \
    -keystore "${OUT_DIR}/${broker}.keystore.jks" \
    -storepass "${PASSWORD}"

  keytool -importcert \
    -noprompt \
    -alias "${broker}" \
    -file "${OUT_DIR}/${broker}.crt" \
    -keystore "${OUT_DIR}/${broker}.keystore.jks" \
    -storepass "${PASSWORD}"
}

create_client_certificate() {
  local client="$1"
  if [[ -f "${OUT_DIR}/${client}.crt" && -f "${OUT_DIR}/${client}.key" ]]; then
    printf 'Client certificate already exists: %s\n' "${client}"
    return
  fi

  openssl req -newkey rsa:2048 -nodes \
    -keyout "${OUT_DIR}/${client}.key" \
    -out "${OUT_DIR}/${client}.csr" \
    -subj "/CN=${client}/OU=Kafka/O=MigrationLab/L=Local/ST=Local/C=US"

  openssl x509 -req \
    -in "${OUT_DIR}/${client}.csr" \
    -CA "${OUT_DIR}/ca.crt" \
    -CAkey "${OUT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${OUT_DIR}/${client}.crt" \
    -days "${DAYS}" \
    -sha256
}

create_truststore() {
  if [[ -f "${OUT_DIR}/kafka.truststore.jks" ]]; then
    printf 'Truststore already exists: %s\n' "${OUT_DIR}/kafka.truststore.jks"
    return
  fi

  keytool -importcert \
    -noprompt \
    -alias CARoot \
    -file "${OUT_DIR}/ca.crt" \
    -keystore "${OUT_DIR}/kafka.truststore.jks" \
    -storepass "${PASSWORD}"
}

main() {
  require_command openssl
  require_command keytool
  mkdir -p "${OUT_DIR}"
  chmod 700 "${OUT_DIR}"

  generate_ca
  create_truststore
  for broker in "${BROKERS[@]}"; do
    create_broker_keystore "${broker}"
  done
  for client in "${CLIENTS[@]}"; do
    create_client_certificate "${client}"
  done
  write_credential_files
  printf 'Generated TLS assets in %s\n' "${OUT_DIR}"
}

main "$@"
