SHELL := /usr/bin/env bash

.PHONY: help test lint validate compose-config compose-up compose-down create-topics precheck migrate verify finalize rollback kustomize-local kustomize-final kustomize-production

help:
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "%-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run repository tests.
	python3 -m unittest discover -s tests -v

lint: ## Run lightweight local lint checks.
	python3 -m unittest tests.test_static_contract -v

validate: test ## Alias for all local validation.

compose-config: ## Validate Docker Compose syntax when Docker is available.
	docker compose -f docker-compose.yml config --quiet

compose-up: ## Start the local ZooKeeper-mode Kafka cluster.
	docker compose up -d zookeeper-1 zookeeper-2 zookeeper-3 kafka-1 kafka-2 kafka-3

compose-down: ## Stop the local cluster but keep persistent volumes.
	docker compose down

create-topics: ## Create sample topics in the local cluster.
	docker compose --profile tools run --rm kafka-init

precheck: ## Run migration pre-checks.
	scripts/precheck.sh

migrate: ## Start KRaft migration phase.
	scripts/migrate.sh

verify: ## Verify migration health.
	scripts/verify.sh

finalize: ## Finalize into KRaft mode; requires CONFIRM_FINALIZE=yes.
	scripts/finalize.sh

rollback: ## Roll back before finalization; requires CONFIRM_ROLLBACK=yes.
	scripts/rollback.sh

kustomize-local: ## Render local Kubernetes manifests.
	kubectl kustomize k8s/overlays/local

kustomize-final: ## Render final KRaft Kubernetes manifests.
	kubectl kustomize k8s/overlays/final-kraft

kustomize-production: ## Render production Kubernetes manifests.
	kubectl kustomize k8s/overlays/production
