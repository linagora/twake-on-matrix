import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/joinable_subspace_row.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../space_home/open_space_child_test.mocks.dart';

void main() {
  setUp(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('JoinableSubspaceRow_whenTapped_joinsItThroughItsVia', (
    tester,
  ) async {
    final repository = MockSpaceRepository();
    when(repository.watchRoomChanges()).thenAnswer((_) => const Stream.empty());
    when(repository.getRoomListEntries()).thenReturn(const []);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: JoinableSubspaceRow(
              row: RoomListJoinableRow(
                const SpaceChannel(
                  roomId: 'sub',
                  name: 'Sub',
                  via: ['good.org'],
                ),
                parentSpaceId: '!s',
                depth: 1,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) => Text('room ${state.pathParameters['roomid']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [spaceRepositoryProvider.overrideWithValue(repository)],
        ),
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Sub'));
    await tester.pumpAndSettle();

    verify(repository.joinRoom('sub', via: ['good.org'])).called(1);
    expect(find.text('room sub'), findsOneWidget);
  });
}
