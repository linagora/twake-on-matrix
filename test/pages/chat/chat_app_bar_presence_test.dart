import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_app_bar_title.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'chat_app_bar_presence_test.mocks.dart';

const _peer = '@bob:server';
const _dotKey = ValueKey('linagora-presence-dot');

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Client>()])
void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  Widget host(Widget child, Stream<PersonPresence?> presence) =>
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            personPresenceProvider(_peer).overrideWith((ref) => presence),
          ],
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  group('DirectChatAppBarStatusContent', () {
    late MockRoom room;

    setUp(() {
      final client = MockClient();
      when(client.userID).thenReturn('@me:server');
      when(client.ignoredUsers).thenReturn([]);
      room = MockRoom();
      when(room.client).thenReturn(client);
      when(room.typingUsers).thenReturn([]);
    });

    Future<void> pumpStatus(
      WidgetTester tester,
      Stream<PersonPresence?> presence, {
      ConnectivityResult connectivity = ConnectivityResult.wifi,
    }) async {
      await tester.pumpWidget(
        host(
          DirectChatAppBarStatusContent(
            connectivityResultStream: Stream.value(connectivity),
            room: room,
            peerId: _peer,
          ),
          presence,
        ),
      );
      await tester.pump();
    }

    testWidgets('says the status is loading before the presence comes', (
      tester,
    ) async {
      await pumpStatus(tester, StreamController<PersonPresence?>().stream);

      expect(find.text('Loading status...'), findsOneWidget);
    });

    testWidgets('says online', (tester) async {
      await pumpStatus(
        tester,
        Stream.value(const PersonPresence(status: PresenceStatus.online)),
      );

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('puts the status before the presence', (tester) async {
      await pumpStatus(
        tester,
        Stream.value(
          const PersonPresence(
            status: PresenceStatus.online,
            statusMessage: 'In a meeting',
          ),
        ),
      );

      expect(find.text('In a meeting · Online'), findsOneWidget);
    });

    testWidgets('says offline without a known activity', (tester) async {
      await pumpStatus(
        tester,
        Stream.value(const PersonPresence(status: PresenceStatus.offline)),
      );

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('says there is no connection before the presence', (
      tester,
    ) async {
      await pumpStatus(
        tester,
        Stream.value(const PersonPresence(status: PresenceStatus.online)),
        connectivity: ConnectivityResult.none,
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });
  });

  group('ChatAppBarPresenceBadge', () {
    Future<void> pumpBadge(WidgetTester tester, PersonPresence presence) async {
      await tester.pumpWidget(
        host(
          const ChatAppBarPresenceBadge(
            peerId: _peer,
            size: 40,
            child: SizedBox.square(dimension: 40),
          ),
          Stream.value(presence),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the dot of an online peer', (tester) async {
      await pumpBadge(
        tester,
        const PersonPresence(status: PresenceStatus.online),
      );

      expect(find.byKey(_dotKey), findsOneWidget);
      expect(
        tester
            .widget<LinagoraPresenceBadge>(find.byType(LinagoraPresenceBadge))
            .presence,
        LinagoraPresence.online,
      );
    });

    testWidgets('shows no dot for an offline peer', (tester) async {
      await pumpBadge(
        tester,
        const PersonPresence(status: PresenceStatus.offline),
      );

      expect(find.byKey(_dotKey), findsNothing);
    });
  });
}
