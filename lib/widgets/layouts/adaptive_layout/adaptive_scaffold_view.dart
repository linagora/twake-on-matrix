import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/settings/settings.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class AppScaffoldView extends StatelessWidget {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;
  final PageController pageController;
  final Future<Profile?> fetchOwnProfile;
  final OnOpenSearchPage onOpenSearchPage;
  final OnCloseSearchPage onCloseSearchPage;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;

  final String? activeRoomId;

  static const ValueKey scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  static const ValueKey shellKey = ValueKey('Body');

  const AppScaffoldView({
    Key? key,
    this.activeRoomId,
    required this.activeNavigationBar,
    required this.pageController,
    required this.fetchOwnProfile,
    required this.onOpenSearchPage,
    required this.onCloseSearchPage,
    required this.onDestinationSelected,
    required this.onClientSelected,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    final responsive = getIt.get<ResponsiveUtils>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (!responsive.isMobile(context)) ...[
            SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                const WidthPlatformBreakpoint(
                  begin: ResponsiveUtils.minDesktopWidth,
                ): SlotLayout.from(
                  key: primaryNavigationKey,
                  builder: (_) {
                    return ValueListenableBuilder(
                      valueListenable: activeNavigationBar,
                      builder: (_, navigatorBar, child) {
                        switch (navigatorBar) {
                          case AdaptiveDestinationEnum.search:
                            return const SizedBox();
                          case AdaptiveDestinationEnum.contacts:
                          case AdaptiveDestinationEnum.rooms:
                          default:
                            return _primaryNavigationBarBuilder(context);
                        }
                      },
                    );
                  },
                )
              },
            ),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
              child: Container(
                decoration: BoxDecoration(
                  color: LinagoraRefColors.material().primary[100],
                ),
                child: PageView(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _triggerPageViewBuilder(
                      navigatorBarType: AdaptiveDestinationEnum.contacts,
                      navigatorBarWidget: ContactsTab(
                        bottomNavigationBar:
                            _bottomNavigationBarBuilder(context),
                      ),
                    ),
                    ChatList(
                      activeRoomId: activeRoomId,
                      bottomNavigationBar: _bottomNavigationBarBuilder(context),
                      onOpenSearchPage: onOpenSearchPage,
                    ),
                    _triggerPageViewBuilder(
                      navigatorBarType: AdaptiveDestinationEnum.settings,
                      navigatorBarWidget: Settings(
                        bottomNavigationBar:
                            _bottomNavigationBarBuilder(context),
                      ),
                    ),
                    _triggerPageViewBuilder(
                      navigatorBarType: AdaptiveDestinationEnum.search,
                      navigatorBarWidget: Search(
                        onCloseSearchPage: onCloseSearchPage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _triggerPageViewBuilder({
    required AdaptiveDestinationEnum navigatorBarType,
    required Widget navigatorBarWidget,
  }) {
    return ValueListenableBuilder<AdaptiveDestinationEnum>(
      valueListenable: activeNavigationBar,
      builder: (context, currentNavigatorBar, child) {
        if (navigatorBarType == currentNavigatorBar) {
          return navigatorBarWidget;
        }
        return const SizedBox();
      },
    );
  }

  Widget _bottomNavigationBarBuilder(BuildContext context) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          end: ResponsiveUtils.maxMobileWidth,
        ): SlotLayout.from(
          key: bottomNavigationKey,
          builder: (_) {
            return Container(
              height: ResponsiveUtils.heightBottomNavigation,
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NavigationBar(
                    height: ResponsiveUtils.heightBottomNavigation,
                    selectedIndex: _getActiveBottomNavigationBarIndex(),
                    destinations: getNavigationDestinations(context),
                    onDestinationSelected: onDestinationSelected,
                  ),
                ],
              ),
            );
          },
        )
      },
    );
  }

  int _getActiveBottomNavigationBarIndex() {
    switch (activeNavigationBar.value) {
      case AdaptiveDestinationEnum.contacts:
        return 0;
      case AdaptiveDestinationEnum.rooms:
        return 1;
      case AdaptiveDestinationEnum.settings:
        return 2;
      default:
        return 1;
    }
  }

  Widget _primaryNavigationBarBuilder(BuildContext context) {
    final destinations = getNavigationDestinations(context);

    return AdaptiveScaffoldPrimaryNavigation(
      myProfile: fetchOwnProfile,
      selectedIndex: activeNavigationBar.value.index,
      getNavigationRailDestinations: destinations
          .map((_) => AdaptiveScaffold.toRailDestination(_))
          .toList(),
      onDestinationSelected: onDestinationSelected,
      onSelected: (object) => onClientSelected(object, context),
    );
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const TwakeNavigationIcon(
          icon: Icons.contacts_outlined,
        ),
        label: L10n.of(context)!.contacts,
      ),
      NavigationDestination(
        icon: UnreadRoomsBadge(
          filter: (room) => !room.isSpace && !room.isStoryRoom,
        ),
        label: L10n.of(context)!.chat,
      ),
      NavigationDestination(
        icon: const TwakeNavigationIcon(
          icon: Icons.settings,
        ),
        label: L10n.of(context)!.settings,
      ),
    ];
  }
}
