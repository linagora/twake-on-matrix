# Patrol Web Integration Tests

Patrol 4.x supports running the same integration tests on Flutter Web via
Chrome (driven by Playwright). This document explains how the local test
loop is wired and how to run the suite.

## TL;DR

```bash
# Terminal 1 — start homeserver + provision fixtures
./scripts/integration-server-synapse.sh
./scripts/integration-test-provision-synapse.sh > .env.patrol-web

# Terminal 2 — run the tests (headless)
set -a && . ./.env.patrol-web && set +a
fvm dart pub global run patrol_cli:main test \
  --device chrome \
  --web-headless=true \
  --dart-define=MATRIX_URL="$MATRIX_URL" \
  --dart-define=SERVER_URL="$SERVER_URL" \
  --dart-define=USERNAME="$USERNAME" \
  --dart-define=PASSWORD="$PASSWORD" \
  --dart-define=Receiver="$Receiver" \
  --dart-define=ReceiverPass="$ReceiverPass" \
  # …other --dart-define values from .env.patrol-web
```

## Why a local Synapse and not production matrix.linagora.com?

Production uses a full SSO (LemonLDAP + OIDC) flow. On mobile, the
`dart:io` `HttpClient` in `CoreRobot.getLoginTokenViaOIDC` walks that
7-step redirect dance directly and feeds a one-time `loginToken` into
`/onAuthRedirect`. On web this bypass is unreachable:

1. Browser XHR cannot read intermediate 302 `Location` headers, so we
   cannot extract `scope` / `state` / `nonce` / `code_challenge` from
   step 1's response.
2. The SSO origin (`sso.linagora.com`) does not expose CORS headers for
   cross-origin XHR from a `localhost:NNNN` test origin — the first
   `package:http` request fails with an `XMLHttpRequest error.`
3. The app's `AutoHomeserverPicker` auto-redirects logged-out web
   sessions to `sso.linagora.com` via `FlutterWebAuth2.authenticate()`,
   which on web does a full-tab `window.location.href =` navigation.
   Playwright loses its JS execution context the moment that fires, and
   the test dies with `Execution context was destroyed`.

Running the suite against a local Synapse with registration enabled and
no SSO sidesteps all three issues:

- The OIDC bypass is not needed — we authenticate with
  `m.login.password`, which Matrix homeservers serve with permissive
  CORS on the Client-Server API (Element Web relies on exactly this).
- `AutoHomeserverPicker` detects an SSO-less, registration-enabled
  homeserver and falls through to `ConnectRoute` — no
  `FlutterWebAuth2.authenticate`, no tab-killing navigation.
- Everything runs against a same-origin `localhost`, so XHR never has
  to cross an origin.

This is the same pattern adopted by
[linagora/tmail-flutter](https://github.com/linagora/tmail-flutter/pull/4452)
for its Twake Mail integration suite.

## Moving parts

| Component | Responsibility |
|-----------|----------------|
| [scripts/integration-server-synapse.sh](../scripts/integration-server-synapse.sh) | Spins up a fresh Synapse in Docker (tmpfs, so empty state every run). |
| [scripts/integration-test-provision-synapse.sh](../scripts/integration-test-provision-synapse.sh) | Registers test users, creates the shared group, seeds a few messages, sets power levels. Outputs an env file with all the `--dart-define` values the suite expects. |
| [integration_test/base/api_login_helper.dart](../integration_test/base/api_login_helper.dart) | Conditional export: mobile uses the SSO OIDC bypass (`…_io.dart`); web uses `m.login.password` (`…_web.dart`). |
| [integration_test/robots/login_robot.dart](../integration_test/robots/login_robot.dart) | `loginViaApi` branches on `kIsWeb`: mobile keeps the existing `/onAuthRedirect` flow; web drives the Matrix SDK directly (`client.login(LoginType.mLoginPassword, …)`). |
| [.github/workflows/patrol-web-integration-test.yaml](../.github/workflows/patrol-web-integration-test.yaml) | CI job on `ubuntu-latest` — starts Docker Synapse, provisions fixtures, runs the headless Patrol suite. |

## Fixture data

The provisioning script creates three test accounts and a shared room
(`TEST_GROUP`) that match the `--dart-define` values the existing tests
read. The defaults are tuned for the current suite:

| Key | Default value |
|-----|---------------|
| `USERNAME` / `PASSWORD` | `alice` / `alicepassword` (room admin) |
| `Receiver` / `ReceiverPass` | `bob` / `bobpassword` (room moderator) |
| `SearchByMatrixAddress` | `@charlie:localhost` |
| `TitleOfGroupTest` / `SearchByTitle` | `TEST_GROUP` |
| `GroupID` | room ID returned by `createRoom` |

Override any of them via environment variables before calling the
script — e.g. `USER1=test_user ./scripts/integration-test-provision-synapse.sh`.

## What about mobile?

Mobile CI is unchanged: it still runs the existing OIDC bypass against
the real homeserver (Firebase Test Lab / self-hosted runner path).
Retargeting mobile onto the local Synapse is a follow-up — feasible, but
requires migrating the test users and their power levels, and a CI
runner with Docker + Android tooling in the same image.

## Known limitations

- Tests that exercise the SSO UI path (autohomeserver-picker redirect,
  LemonLDAP captcha, OIDC consent) cannot run against a local Synapse
  without SSO. Those stay mobile-only.
- Backend state is shared across tests within a run (same Docker
  container), matching the mobile approach established in the original
  Patrol setup ADR. Fresh state between runs is free (tmpfs).
