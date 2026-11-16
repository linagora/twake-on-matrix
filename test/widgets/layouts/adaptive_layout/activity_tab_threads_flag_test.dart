import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body_view.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

/// Review of PR #3624 (blocker): the Activity tab belongs to the threads.
/// With [AppConfig.threadsEnabled] off, the bar and the pages are those of
/// main: Contacts · Chats · Settings, no Activity tab nor page. With the
/// flag on: Contacts · Chats · Activity · Settings, as the PR shows them.
void main() {
  late bool flagBefore;

  setUp(() => flagBefore = AppConfig.threadsEnabled);
  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  /// The tabs of the bar, as the screen builds it.
  List<AdaptiveDestinationEnum> barTabs() =>
      AppAdaptiveScaffoldBodyController().destinations;

  /// The number of pages the tabs of a phone switch between. No page is
  /// built: the page shown is Contacts, while Chats is the tab selected.
  Future<int?> pageCount(WidgetTester tester) async {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final selected = ValueNotifier(AdaptiveDestinationEnum.rooms);
    final pages = PageController();
    final profile = ValueNotifier<Profile?>(null);
    final room = ValueNotifier<String?>(null);
    addTearDown(() {
      selected.dispose();
      pages.dispose();
      profile.dispose();
      room.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AppAdaptiveScaffoldBodyView(
          activeRoomIdNotifier: room,
          pageController: pages,
          activeNavigationBarNotifier: selected,
          onDestinationSelected: (_) {},
          onClientSelected: (_, _) {},
          destinations: barTabs(),
          onPopInvoked: (_) {},
          onOpenSettings: () {},
          currentProfile: profile,
        ),
      ),
    );
    return tester
        .widget<PageView>(find.byType(PageView))
        .childrenDelegate
        .estimatedChildCount;
  }

  group('threads off: as on main', () {
    setUp(() => AppConfig.threadsEnabled = false);

    test('the bar has no Activity tab', () {
      expect(barTabs(), [
        AdaptiveDestinationEnum.contacts,
        AdaptiveDestinationEnum.rooms,
        AdaptiveDestinationEnum.settings,
      ]);
    });

    testWidgets('there is no Activity page: one page per tab', (tester) async {
      expect(await pageCount(tester), 3);
    });
  });

  group('threads on', () {
    setUp(() => AppConfig.threadsEnabled = true);

    test('the bar goes Contacts, Chats, Activity, Settings', () {
      expect(barTabs(), [
        AdaptiveDestinationEnum.contacts,
        AdaptiveDestinationEnum.rooms,
        AdaptiveDestinationEnum.activity,
        AdaptiveDestinationEnum.settings,
      ]);
    });

    testWidgets('the Activity page is there: one page per tab', (tester) async {
      expect(await pageCount(tester), 4);
    });
  });
}
