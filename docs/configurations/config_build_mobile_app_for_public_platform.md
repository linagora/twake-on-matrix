## Configuring apps with compilation environment declarations

### Context

- Twake Chat app can use the values of environment declarations to change its functionality or behavior. 
  Dart compilers can eliminate the code made unreachable due to 
  control flow using the environment declaration values.
- Only support for mobile app.

### How to config

1.Flutter
- To specify environment declarations to the Flutter tool, use the `--dart-define` option instead:

```
flutter run --dart-define=REGISTRATION_URL=https://example.com/ 
--dart-define=TWAKE_WORKPLACE_HOMESERVER=https://example.com/ 
--dart-define=PLATFORM=platfomrm 
--dart-define=HOME_SERVER=https://example.com/ 

```

- `REGISTRATION_URL`: Registration URL for public platform
- `TWAKE_WORKPLACE_HOMESERVER`: Twake workplace homeserver
- `PLATFORM`: Platform, `saas` for the case of public platform
- `HOME_SERVER`: Homeserver

If you want to disable it, please change the value or remove when use `--dart-define` option