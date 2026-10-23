# 37. Cozy bridge for the Drive session

Date: 2026-10-08

## Status

Proposed

## Context

- "Add from Drive" needs `POST /intents` on the user's Twake stack, as the user.
- On web, Chat runs in an iframe of the Cozy shell, which holds the stack session.
  Chat already uses `cozy-external-bridge` for notifications and history syncing.
- Chat only has Matrix tokens. Drive's `/auth/token_exchange` rejects them
  (`400 invalid token`) and wants an SSO `id_token`, which Chat never receives.
- From the browser, `/auth/token_exchange` is blocked by CORS.
- Bridge `fetchJSON` exists from 1.3.0 (absent in 0.8.0, 0.16.1, 1.1.0 to 1.2.3).
  The shell runs it with its own session: `{method, path, body}` goes to
  `client.stackClient.fetchJSON` (`cozy-libs`, `useListenBridgeRequests.ts`).

## Decision

- Inside the container, create the intent with `fetchJSON('POST', '/intents')`.
  Chat holds no Drive token.
- Bridge 1.3.0 is the minimum. `AppConfig` and `config.sample.json` move to it;
  a deploy `config.json` must not pin an older version.
- `CozyBridge` is a two-member interface over the bridge:

```dart
bool get isAvailable;
Future<Object?> fetchJson({method, path, body});
```

- `isAvailable` means `window._cozyBridge` has `fetchJSON`. It is read on every
  call, because `setupBridge()` replaces the whole object, and checked when the
  user acts, because `initialize()` is not awaited at startup.
- A bridge failure is the action's failure. It is never replayed over the token
  path, since the request may already have reached the stack.
- `CozyConfigManager` stays as is. It has no `fetchJSON`, and upgrading
  `linagora_design_flutter` is out of scope.
- The request body follows the Twake Drive spec, not Twake Mail ADR-0095
  (outdated): options go in `attributes.data`, and `"downloadLink": null`
  hides the attachment button.

## Consequences

- Drive works only inside the Twake container for now.
- Moving web builds to 1.3.0 is the only change that can affect existing
  features (notifications, history syncing, "inside Cozy").
- The `{method, path, body}` shape is documented in code only.
- `DriveTokenDatasource` exists but no use case calls it yet.
- Token path errors: 400 on `token_exchange` and 401/403 become
  `DriveAuthRejectedException` (the caller may fetch a fresh token and retry,
  as Twake Mail does); everything else is `DriveRequestFailedException`.

## TODO

- Give Chat an SSO client (OIDC code with PKCE) to get the `id_token`. This
  unlocks Drive on mobile and on web outside Twake.

## Not verified yet

- `fetchJSON` with `POST /intents` in a deployed container, and whether it needs
  `?force_session_id=true`.
- Notifications, history syncing and "inside Cozy" with 1.3.0.

## Sources

- `cozy/cozy-libs`: `cozy-external-bridge`; `linagora/cozy-libs`:
  `cozy-external-bridge-container`
- `linagora/twake-drive`: `docs/file-picker-intent.md`
- Twake Mail ADR-0095, ADR-0108 (reference only)
