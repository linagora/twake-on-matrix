import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

HomeserverSummary _summary(
  Map<String, Object?> wellKnown, {
  bool driveTurnedOn = true,
}) => HomeserverSummary(
  discoveryInformation: DiscoveryInformation.fromJson({
    'm.homeserver': {'base_url': 'https://matrix.example/'},
    if (driveTurnedOn) 'app.twake.chat': {'enable_twake_drive': true},
    ...wellKnown,
  }),
  versions: GetVersionsResponse(versions: const ['v1.11']),
  loginFlows: const [],
);

class _Account extends Fake implements Client {
  _Account(this.homeserver);

  @override
  Uri? homeserver;
}

void main() {
  late ProviderContainer container;
  Client? active;

  setUp(() {
    active = null;
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [activeMatrixClientProvider.overrideWith((ref) => active)],
    );
  });

  Client accountOn(String homeserver) => _Account(Uri.parse(homeserver));

  void advertise(HomeserverSummary? summary) =>
      container.read(loginHomeserverSummaryProvider.notifier).set(summary);

  group('driveConfigProvider', () {
    test('is off when the homeserver does not turn Drive on, even with an '
        'issuer', () {
      advertise(
        _summary({
          'm.authentication': {'issuer': 'https://sso.example/'},
        }, driveTurnedOn: false),
      );

      expect(container.read(driveConfigProvider).isEnabled, isFalse);
    });

    test('serves the active account of the homeserver that advertises it', () {
      active = accountOn('https://matrix.example');
      advertise(
        _summary({
          'm.authentication': {'issuer': 'https://sso.example/'},
        }),
      );

      expect(container.read(driveConfigProvider).isEnabled, isTrue);
    });

    test('is off for an active account of another homeserver, as while an '
        'account is being added there', () {
      active = accountOn('https://matrix.other.example');
      advertise(
        _summary({
          'm.authentication': {'issuer': 'https://sso.example/'},
        }),
      );

      expect(container.read(driveConfigProvider).isEnabled, isFalse);
    });

    test('is off before any homeserver is known', () {
      final config = container.read(driveConfigProvider);

      expect(config.isEnabled, isFalse);
    });

    test('takes the SSO from the issuer in the well-known', () {
      advertise(
        _summary({
          'm.authentication': {'issuer': 'https://sso.example/'},
        }),
      );

      final config = container.read(driveConfigProvider);

      expect(config.ssoUrl, 'https://sso.example/');
      expect(config.ssoClientId, 'twake-chat-mobile');
      expect(config.isEnabled, isTrue);
    });

    test('is off for a homeserver that advertises no issuer', () {
      advertise(_summary({}));

      expect(container.read(driveConfigProvider).isEnabled, isFalse);
    });

    test('is off when the issuer is not a string', () {
      advertise(
        _summary({
          'm.authentication': {'issuer': 42},
        }),
      );

      expect(container.read(driveConfigProvider).isEnabled, isFalse);
    });

    test('follows the homeserver of the account that becomes active', () {
      advertise(
        _summary({
          'm.authentication': {'issuer': 'https://sso.example/'},
        }),
      );
      expect(container.read(driveConfigProvider).isEnabled, isTrue);

      advertise(_summary({}));

      expect(container.read(driveConfigProvider).isEnabled, isFalse);
    });
  });
}
