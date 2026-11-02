import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/empty_state/linagora_empty_state.dart';
import 'package:linagora_design_flutter/list_item/linagora_avatar_list_item.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_page.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  late FakePublicRoomsRepository repository;

  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          publicRoomsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: PublicRoomsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakePublicRoomsRepository(
      directory: [
        publicRoom('!eq', name: 'Équipe', topic: 'The team', memberCount: 1),
        publicRoom(
          '!news',
          name: 'News',
          kind: PublicRoomKind.feed,
          access: PublicRoomAccess.approval,
          memberCount: 12,
        ),
      ],
    );
  });

  testWidgets('build_always_showsNameAccessMembersAndTopic', (tester) async {
    // Act
    await pumpPage(tester);

    // Assert
    expect(find.byType(LinagoraAvatarListItem), findsNWidgets(2));
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Join · 1 member · The team'), findsOneWidget);
    expect(find.text('Ask to join · 12 members'), findsOneWidget);
  });

  testWidgets('search_whenTypedWithoutAccents_findsTheAccentedName', (
    tester,
  ) async {
    // Arrange
    await pumpPage(tester);

    // Act
    await tester.enterText(find.byType(TextField), 'equi');
    await tester.pump();

    // Assert
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('News'), findsNothing);
  });

  testWidgets('search_whenNothingMatches_showsTheEmptyState', (tester) async {
    // Arrange
    await pumpPage(tester);

    // Act
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    // Assert
    expect(find.byType(LinagoraEmptyState), findsOneWidget);
    expect(find.text('No public group to join.'), findsOneWidget);
  });

  testWidgets('build_whenTheDirectoryIsEmpty_showsTheEmptyState', (
    tester,
  ) async {
    // Arrange
    repository.directory = [];

    // Act
    await pumpPage(tester);

    // Assert
    expect(find.text('No public group to join.'), findsOneWidget);
  });

  testWidgets('build_whenTheDirectoryFails_offersARetry', (tester) async {
    // Arrange
    repository.fetchError = PublicRoomsFetchFailedException(
      cause: Exception('down'),
    );
    await pumpPage(tester);
    repository.fetchError = null;

    // Act
    await tester.tap(find.byType(LinagoraEmptyState));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(LinagoraAvatarListItem), findsNWidgets(2));
  });

  testWidgets('tap_onARoomOnApproval_saysAnAdminMustApproveAndStays', (
    tester,
  ) async {
    // Arrange
    await pumpPage(tester);

    // Act
    await tester.tap(find.text('News'));
    await tester.pump();

    // Assert
    expect(repository.knockedIds, ['!news']);
    expect(
      find.text('Request sent: an administrator has to approve it.'),
      findsOneWidget,
    );
    expect(find.byType(PublicRoomsPage), findsOneWidget);
  });

  testWidgets('tap_whenTheJoinFails_saysSo', (tester) async {
    // Arrange
    repository.joinError = PublicRoomJoinFailedException(
      cause: Exception('forbidden'),
    );
    await pumpPage(tester);

    // Act
    await tester.tap(find.text('Équipe'));
    await tester.pump();

    // Assert
    expect(find.text('This group could not be joined.'), findsOneWidget);
  });
}
