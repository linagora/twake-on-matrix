import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_search_style.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body_view.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

import '../../../providers/personalization/fake_display_preferences_repository.dart';

// D37 and the review of #3824: the search style of the chat list on a phone,
// `ChatListSearchStyle.collapsing` or the bottom bar, is the user's choice in
// the personalization. The Chats tab of the app hands the chosen style to
// its ChatList; what each style shows is in
// test/pages/chat_list/chat_list_collapsing_search_test.dart.

/// The Chats tab of a phone, on a device whose storage holds [stored]. No
/// page is built: the ChatList given to the tabs is read as it is.
Future<ProviderContainer> _pumpTabs(
  WidgetTester tester, {
  DisplayPreferencesState stored = const DisplayPreferencesState(),
}) async {
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
  final searchOpen = ValueNotifier(false);
  final query = TextEditingController();
  addTearDown(() {
    selected.dispose();
    pages.dispose();
    profile.dispose();
    room.dispose();
    searchOpen.dispose();
    query.dispose();
  });
  final container = ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      displayPreferencesRepositoryProvider.overrideWithValue(
        FakeDisplayPreferencesRepository(stored: stored),
      ),
    ],
  );
  // The storage has answered, as once the app has started.
  await container.read(displayPreferencesControllerProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: AppAdaptiveScaffoldBodyView(
          activeRoomIdNotifier: room,
          pageController: pages,
          activeNavigationBarNotifier: selected,
          onDestinationSelected: (_) {},
          onClientSelected: (_, _) {},
          destinations: AppAdaptiveScaffoldBodyController().destinations,
          onPopInvoked: (_) {},
          onOpenSettings: () {},
          currentProfile: profile,
          searchOpen: searchOpen,
          searchQuery: query,
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// The ChatList the tabs hold, as given to them.
ChatList _chatList(WidgetTester tester) =>
    (tester.widget<PageView>(find.byType(PageView)).childrenDelegate
            as SliverChildListDelegate)
        .children
        .whereType<ChatList>()
        .single;

void main() {
  group('the search of the chat list on a phone, chosen in the '
      'personalization', () {
    testWidgets('nothing chosen: the bottom bar, as today', (tester) async {
      await _pumpTabs(tester);

      expect(_chatList(tester).searchStyle, ChatListSearchStyle.bottomBar);
    });

    testWidgets('« collapsing » stored on the device: the thin field at the '
        'top of the list', (tester) async {
      await _pumpTabs(
        tester,
        stored: const DisplayPreferencesState(
          searchStyle: ChatListSearchStyle.collapsing,
        ),
      );

      expect(_chatList(tester).searchStyle, ChatListSearchStyle.collapsing);
    });

    testWidgets('a choice made in the flow or the settings applies at once', (
      tester,
    ) async {
      final container = await _pumpTabs(tester);

      container
          .read(displayPreferencesControllerProvider.notifier)
          .setSearchStyle(ChatListSearchStyle.collapsing);
      await tester.pump();

      expect(_chatList(tester).searchStyle, ChatListSearchStyle.collapsing);
    });

    testWidgets('taken back to the bottom bar: the bottom bar again', (
      tester,
    ) async {
      final container = await _pumpTabs(
        tester,
        stored: const DisplayPreferencesState(
          searchStyle: ChatListSearchStyle.collapsing,
        ),
      );

      container
          .read(displayPreferencesControllerProvider.notifier)
          .setSearchStyle(ChatListSearchStyle.bottomBar);
      await tester.pump();

      expect(_chatList(tester).searchStyle, ChatListSearchStyle.bottomBar);
    });

    testWidgets('the search stays the one of the tabs, whatever the style', (
      tester,
    ) async {
      await _pumpTabs(
        tester,
        stored: const DisplayPreferencesState(
          searchStyle: ChatListSearchStyle.collapsing,
        ),
      );

      expect(_chatList(tester).searchOpen, isNotNull);
      expect(_chatList(tester).searchResults, isNotNull);
    });
  });
}
