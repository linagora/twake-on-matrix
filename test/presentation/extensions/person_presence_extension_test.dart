import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/extensions/person_presence_extension.dart';

PersonPresence _seen(
  Duration ago, {
  PresenceStatus status = PresenceStatus.away,
}) =>
    PersonPresence(status: status, lastActiveAt: DateTime.now().subtract(ago));

void main() {
  final l10n = lookupL10n(const Locale('en'));

  group('badge', () {
    test('maps each status to its dot', () {
      expect(
        PresenceStatus.values.map(
          (status) => PersonPresence(status: status).badge,
        ),
        [
          LinagoraPresence.online,
          LinagoraPresence.away,
          LinagoraPresence.offline,
        ],
      );
    });
  });

  group('localizedPresence', () {
    test('says online only when online', () {
      expect(
        const PersonPresence(
          status: PresenceStatus.online,
        ).localizedPresence(l10n),
        'Online',
      );
      expect(
        _seen(const Duration(seconds: 10)).localizedPresence(l10n),
        'online 1m ago',
      );
    });

    test('says offline without a last activity', () {
      expect(
        const PersonPresence(
          status: PresenceStatus.offline,
        ).localizedPresence(l10n),
        'Offline',
      );
    });

    test('counts minutes, hours, then days', () {
      expect(
        _seen(const Duration(minutes: 5)).localizedPresence(l10n),
        'online 5m ago',
      );
      expect(
        _seen(const Duration(hours: 3)).localizedPresence(l10n),
        'online 3h ago',
      );
      expect(
        _seen(const Duration(days: 4)).localizedPresence(l10n),
        'online 4d ago',
      );
    });

    test('says a while ago after 30 days', () {
      expect(
        _seen(const Duration(days: 45)).localizedPresence(l10n),
        'a while ago',
      );
    });
  });

  group('localizedSubtitle', () {
    test('puts the status before the presence', () {
      expect(
        const PersonPresence(
          status: PresenceStatus.online,
          statusMessage: 'In a meeting',
        ).localizedSubtitle(l10n),
        'In a meeting · Online',
      );
    });

    test('is the presence alone without a status', () {
      expect(
        const PersonPresence(
          status: PresenceStatus.online,
        ).localizedSubtitle(l10n),
        'Online',
      );
    });
  });
}
