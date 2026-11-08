import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/pages/new_group/new_group.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

/// The real route of `$appRoutes` with this [path], searched depth first.
GoRoute? _find(List<RouteBase> routes, String path) {
  for (final route in routes) {
    if (route is GoRoute && route.path == path) return route;
    final found = _find(route.routes, path);
    if (found != null) return found;
  }
  return null;
}

/// Keeps the real parsing and the real `buildPage`, but records the page the
/// route built and shows a stand-in instead: the real pages need GetIt.
GoRoute _recording(GoRoute real, List<Widget> built) => GoRoute(
  path: real.path,
  pageBuilder: (context, state) {
    final page = real.pageBuilder!(context, state);
    built.add((page as dynamic).child as Widget);
    return MaterialPage(child: Text('shown ${real.path}'));
  },
  routes: [
    for (final child in real.routes)
      if (child is GoRoute) _recording(child, built),
  ],
);

void main() {
  late List<Widget> built;

  // `_defaultPage` asks GetIt whether the screen is mobile.
  setUpAll(() => GetIt.instance.registerSingleton(ResponsiveUtils()));
  tearDownAll(GetIt.instance.reset);

  Future<GoRouter> open(WidgetTester tester, String location) async {
    built = [];
    final newPrivateChat = _find($appRoutes, 'newprivatechat')!;
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/rooms',
          builder: (_, _) => const Text('rooms'),
          routes: [
            GoRoute(
              path: 'newprivatechat',
              builder: (_, _) => const Text('newprivatechat'),
              routes: [
                for (final child in newPrivateChat.routes)
                  if (child is GoRoute) _recording(child, built),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  T last<T>() => built.whereType<T>().last;

  const contact = PresentationContact(
    matrixId: '@alice:example.org',
    displayName: 'Alice',
  );

  group('NewPrivateChatNewSpaceRoute', () {
    testWidgets('whenOpenedFirstWithoutParent_createsATopLevelSpace', (
      tester,
    ) async {
      await open(tester, '/rooms/newprivatechat/newspace');

      expect(tester.takeException(), isNull);
      expect(find.text('shown newspace'), findsOneWidget);
      final page = last<NewGroup>();
      expect(page.kind, NewGroupKind.space);
      expect(page.parentSpaceId, isNull);
    });

    testWidgets('whenOpenedWithParent_createsASubspaceOfIt', (tester) async {
      await open(tester, '/rooms/newprivatechat/newspace?parent=%21s');

      final page = last<NewGroup>();
      expect(page.kind, NewGroupKind.space);
      expect(page.parentSpaceId, '!s');
    });

    test('location_carriesTheParent', () {
      expect(
        const NewPrivateChatNewSpaceRoute(parent: '!s:x').location,
        '/rooms/newprivatechat/newspace?parent=%21s%3Ax',
      );
      expect(
        const NewPrivateChatNewSpaceRoute().location,
        '/rooms/newprivatechat/newspace',
      );
    });
  });

  group('NewPrivateChatNewSpaceInfoRoute', () {
    testWidgets('whenOpenedFirstWithoutExtra_showsNoMemberAndDoesNotCrash', (
      tester,
    ) async {
      await open(tester, '/rooms/newprivatechat/newspace/newspaceinfo');

      expect(tester.takeException(), isNull);
      expect(find.text('shown newspaceinfo'), findsOneWidget);
      final page = last<NewGroupChatInfo>();
      expect(page.kind, NewGroupKind.space);
      expect(page.contactsList, isEmpty);
      expect(page.parentSpaceId, isNull);
    });

    testWidgets('whenOpenedWithContactsAndParent_keepsBoth', (tester) async {
      final router = await open(tester, '/rooms/newprivatechat');

      router.go(
        '/rooms/newprivatechat/newspace/newspaceinfo?parent=%21s',
        extra: {contact},
      );
      await tester.pumpAndSettle();

      final page = last<NewGroupChatInfo>();
      expect(page.kind, NewGroupKind.space);
      expect(page.contactsList, {contact});
      expect(page.parentSpaceId, '!s');
    });

    test('location_carriesTheParent', () {
      expect(
        const NewPrivateChatNewSpaceInfoRoute(parent: '!s').location,
        '/rooms/newprivatechat/newspace/newspaceinfo?parent=%21s',
      );
    });
  });

  group('NewPrivateChatNewGroupInfoRoute', () {
    testWidgets('whenOpenedFromASpace_createsTheGroupInIt', (tester) async {
      final router = await open(tester, '/rooms/newprivatechat');

      router.go(
        '/rooms/newprivatechat/newgroup/newgroupinfo?parent=%21s',
        extra: {contact},
      );
      await tester.pumpAndSettle();

      final page = last<NewGroupChatInfo>();
      expect(page.kind, isNot(NewGroupKind.space));
      expect(page.contactsList, {contact});
      expect(page.parentSpaceId, '!s');
    });

    testWidgets('whenOpenedFirstWithoutExtra_showsNoMember', (tester) async {
      await open(tester, '/rooms/newprivatechat/newgroup/newgroupinfo');

      expect(tester.takeException(), isNull);
      final page = last<NewGroupChatInfo>();
      expect(page.contactsList, isEmpty);
      expect(page.parentSpaceId, isNull);
    });

    test('location_carriesTheParent', () {
      expect(
        const NewPrivateChatNewGroupInfoRoute(parent: '!s').location,
        '/rooms/newprivatechat/newgroup/newgroupinfo?parent=%21s',
      );
    });
  });
}
