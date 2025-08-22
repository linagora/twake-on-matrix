#!/bin/bash
# Run patrol chat list test with env variables

patrol test \
  -t integration_test/tests/chat/chat_group_test.dart \
  --dart-define-from-file=.env.local.do-not-commit \
  --device "$(grep -E '^DEVICE=' .env | cut -d= -f2-)"