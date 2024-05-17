## Configuring apps with compilation environment declarations

### Context

- Twake Chat need to config env for Twake Chat service on mobile app for public platform, two ways
  to config env:

#### 1. Enable for `SaaS` platform

1.1. Use `--dart-define` option to config env for mobile app.

- Specify `platform` is `saas`.
- To specify environment declarations to the Flutter tool, use the `--dart-define` option instead:

```
flutter run --dart-define=REGISTRATION_URL=https://example.com/ 
--dart-define=TWAKE_WORKPLACE_HOMESERVER=https://example.com/ 
--dart-define=PLATFORM=saas 
--dart-define=HOME_SERVER=https://example.com/ 

```

1.2. Use `config_saas.dart` to config env for mobile app.

```
class ConfigurationSaas {
  static const String registrationUrl = 'https://example.com/';

  static const String twakeWorkplaceHomeserver = 'https://example.com/';

  static const String homeserver = 'https://example.com/';

  static const String platform = 'saas';
}
```

#### 2. Disable for `SaaS` platform

- Build without `--dart-define`.

- Change the value `platform` in `config_saas.dart` to any value except `saas`.

```
class ConfigurationSaas {

  // ...
  
  static const String platform = 'platform';
}
```