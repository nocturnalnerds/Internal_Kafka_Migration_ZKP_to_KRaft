SHELL := /usr/bin/env bash

.PHONY: help test lint validate

help:
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "%-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: ## Run repository tests.
	python3 -m unittest discover -s tests -v

lint: ## Run lightweight local lint checks.
	python3 -m unittest tests.test_static_contract -v

validate: test ## Alias for all local validation.

