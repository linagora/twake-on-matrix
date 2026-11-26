import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/profile_info/profile_info_body/profile_info_header.dart';

Widget _host(PersonPresence presence) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: L10n.localizationsDelegates,
  supportedLocales: L10n.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 160,
        child: PresenceSubtitle(presence: presence, style: null),
      ),
    ),
  ),
);

void main() {
  testWidgets('a long status gives way, the presence stays whole', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PersonPresence(
          status: PresenceStatus.online,
          statusMessage: 'Away at the conference all week, back on Monday',
        ),
      ),
    );

    final status = tester.widget<Text>(
      find.textContaining('Away at the conference'),
    );
    expect(status.maxLines, 1);
    expect(status.overflow, TextOverflow.ellipsis);
    expect(find.text('Online'), findsOneWidget);
    expect(
      tester.getRect(find.text('Online')).right,
      lessThanOrEqualTo(tester.getRect(find.byType(PresenceSubtitle)).right),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the presence alone without a status', (tester) async {
    await tester.pumpWidget(
      _host(const PersonPresence(status: PresenceStatus.offline)),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.textContaining(' · '), findsNothing);
  });
}
