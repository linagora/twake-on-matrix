import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/participant_list_item/participant_list_item.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';

import 'participant_list_item_presence_test.mocks.dart';

const _alice = '@alice:server';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<Room>()])
void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('shows the presence of the member on their avatar', (
    tester,
  ) async {
    final member = MockUser();
    when(member.id).thenReturn(_alice);
    when(member.room).thenReturn(MockRoom());
    when(member.membership).thenReturn(Membership.join);
    when(member.calcDisplayname()).thenReturn('Alice');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            syncedPersonPresenceProvider(_alice).overrideWith(
              (ref) => Stream.value(
                const PersonPresence(status: PresenceStatus.online),
              ),
            ),
          ],
        ),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light, null),
            home: Scaffold(body: ParticipantListItem(member)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final badge = tester.widget<PersonPresenceBadge>(
      find.byType(PersonPresenceBadge),
    );
    expect(badge.userId, _alice);
    expect(find.byKey(const ValueKey('linagora-presence-dot')), findsOne);
  });
}
