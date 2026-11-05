import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
import 'package:twake_chat/domain/model/public_rooms/room_address.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_sheet.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  const alias = '#general:hs';
  late FakePublicRoomsRepository repository;

  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(() => repository = FakePublicRoomsRepository());

  /// The sheet opened from a home route, in a router that knows the room.
  Future<GoRouter> pumpSheet(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => unawaited(
                showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const PublicRoomPreviewSheet(
                    address: RoomAddress(alias),
                    eventId: r'$event',
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) => Text(
            'room ${state.pathParameters['roomid']} '
            '${state.uri.queryParameters['event']}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          publicRoomsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return router;
  }

  PublicRoom general({
    PublicRoomAccess access = PublicRoomAccess.open,
    String? topic = 'Everything',
  }) => PublicRoom(
    roomId: '!general:hs',
    name: 'General',
    topic: topic,
    memberCount: 3,
    access: access,
    kind: PublicRoomKind.group,
  );

  testWidgets('sheet_whenTheRoomIsOpen_showsNameTopicAndJoin', (tester) async {
    // Arrange
    repository.preview = PublicRoomPreview.found(general());

    // Act
    await pumpSheet(tester);

    // Assert
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Everything'), findsOneWidget);
    expect(find.text('Join · 3 members'), findsOneWidget);
  });

  testWidgets('sheet_whenOnApproval_offersToAsk', (tester) async {
    // Arrange
    repository.preview = PublicRoomPreview.found(
      general(access: PublicRoomAccess.approval, topic: null),
    );

    // Act
    await pumpSheet(tester);
    await tester.tap(find.text('Ask to join · 3 members'));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.knockedIds, [alias]);
    expect(find.text('Ask to join · 3 members'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('sheet_whenBanned_saysSoWithoutAButton', (tester) async {
    // Arrange
    repository.preview = const PublicRoomPreview.banned();

    // Act
    await pumpSheet(tester);

    // Assert
    expect(find.text('You have been banned from this chat'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('sheet_whenUnavailable_offersToTryToJoin', (tester) async {
    // Arrange
    repository.preview = const PublicRoomPreview.unavailable();

    // Act
    await pumpSheet(tester);

    // Assert
    expect(find.text('This group is unavailable.'), findsOneWidget);
    expect(find.text('Try to join'), findsOneWidget);
  });

  testWidgets('sheet_whenTheLookupFails_saysUnavailable', (tester) async {
    // Arrange
    repository.previewError = const PublicRoomsNoClientException();

    // Act
    await pumpSheet(tester);

    // Assert
    expect(find.text('This group is unavailable.'), findsOneWidget);
  });

  testWidgets('sheet_whenJoined_opensTheRoomAtTheEvent', (tester) async {
    // Arrange
    repository.preview = PublicRoomPreview.found(general());
    await pumpSheet(tester);

    // Act
    await tester.tap(find.text('Join · 3 members'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(r'room !general:hs $event'), findsOneWidget);
  });

  testWidgets('sheet_whenAlreadyJoined_opensTheRoomAtTheEvent', (tester) async {
    // Arrange
    repository.preview = const PublicRoomPreview.joined('!general:hs');

    // Act
    await pumpSheet(tester);

    // Assert
    expect(find.text(r'room !general:hs $event'), findsOneWidget);
  });

  testWidgets('sheet_whenTheJoinFails_staysOpen', (tester) async {
    // Arrange
    repository
      ..preview = PublicRoomPreview.found(general())
      ..joinError = PublicRoomJoinFailedException(cause: Exception('no'));
    await pumpSheet(tester);

    // Act
    await tester.tap(find.text('Join · 3 members'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('This group could not be joined.'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
  });
}
