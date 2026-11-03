import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/space_home/open_space_child.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'open_space_child_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>()])
void main() {
  late MockSpaceRepository repository;

  Future<void> pumpAndTap(WidgetTester tester, SpaceChannel child) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => openSpaceChild(
                  context,
                  ref,
                  parentSpaceId: '!s',
                  child: child,
                ),
                child: const Text('open'),
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
    repository = MockSpaceRepository();
    when(repository.watchRoomChanges()).thenAnswer((_) => const Stream.empty());
    when(repository.getRoomListEntries()).thenReturn(const []);
  });

  group('openSpaceChild', () {
    testWidgets('whenJoined_opensItWithoutJoining', (tester) async {
      await pumpAndTap(
        tester,
        const SpaceChannel(roomId: 'c', name: 'Dev', isJoined: true),
      );

      expect(find.text('room c'), findsOneWidget);
      verifyNever(repository.joinRoom(any, via: anyNamed('via')));
    });

    testWidgets('whenOnAPhone_backReturnsToTheCard', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpAndTap(
        tester,
        const SpaceChannel(roomId: 'c', name: 'Dev', isJoined: true),
      );
      expect(find.text('room c'), findsOneWidget);

      GoRouter.of(tester.element(find.text('room c'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('whenNotJoined_joinsThroughItsViaThenOpensIt', (tester) async {
      await pumpAndTap(
        tester,
        const SpaceChannel(roomId: 'c', name: 'Dev', via: ['good.org']),
      );

      verify(repository.joinRoom('c', via: ['good.org'])).called(1);
      expect(find.text('room c'), findsOneWidget);
    });

    testWidgets('whenJoinFails_staysAndTellsIt', (tester) async {
      when(
        repository.joinRoom(any, via: anyNamed('via')),
      ).thenThrow(const SpaceJoinFailedException());

      await pumpAndTap(tester, const SpaceChannel(roomId: 'c', name: 'Dev'));

      expect(find.text('room c'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('Could not join.'), findsOneWidget);
    });
  });
}
