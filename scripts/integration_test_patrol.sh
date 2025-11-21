#!/bin/bash
# Run patrol chat list test with env variables

ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"