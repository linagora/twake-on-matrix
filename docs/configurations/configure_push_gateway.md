## Configuration for push gateway

1. get the push gateway url and add the postfix
```
{pushGatewayUrl}/_matrix/push/v1/notify
```
Fx: `https://sygnal.domain.dev/_matrix/push/v1/notify`

2. build the app with `--dart-define` and the param `PUSH_NOTIFICATIONS_GATEWAY_URL`

Fx:
```
flutter build  apk --release --dart-define=PUSH_NOTIFICATIONS_GATEWAY_URL=https://sygnal.domain.dev/_matrix/push/v1/notify
```
