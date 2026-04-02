#!/bin/bash
# Run patrol perf test with env variables

ENV_FILE=integration_test/.env.local.do-not-commit

patrol test \
  --release \
  --no-generate-bundle \
  --show-flutter-logs \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)" \
  --verbose