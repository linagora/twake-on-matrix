import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AppScaffoldView extends StatelessWidget {
  final AdaptiveScaffoldAppController controller;

  final String? activeChat;

  static const ValueKey scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  static const ValueKey shellKey = ValueKey('Body');

  const AppScaffoldView({
    Key? key,
    required this.controller,
    this.activeChat,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    final responsive = getIt.get<ResponsiveUtils>();
    return Scaffold(
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
                      valueListenable: controller.activeNavigationBar,
                      builder: (_, navigatorBar, child) {
                        switch (navigatorBar) {
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
            Container(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ],
          Expanded(
            child: ValueListenableBuilder<AdaptiveDestinationEnum>(
              valueListenable: controller.activeNavigationBar,
              builder: (context, navigatorBar, child) {
                switch (navigatorBar) {
                  case AdaptiveDestinationEnum.contacts:
                    return ContactsTab(
                      bottomNavigationBar: _bottomNavigationBarBuilder(context),
                    );
                  case AdaptiveDestinationEnum.rooms:
                    return child!;
                  case AdaptiveDestinationEnum.search:
                    return Search(
                      callBack: () {
                        controller.activeNavigationBar.value =
                            AdaptiveDestinationEnum.rooms;
                      },
                    );
                  default:
                    return child!;
                }
              },
              child: ChatList(
                activeChat: activeChat,
                bottomNavigationBar: _bottomNavigationBarBuilder(context),
                onTapSearch: () {
                  controller.activeNavigationBar.value =
                      AdaptiveDestinationEnum.search;
                },
              ),
            ),
          ),
        ],
      ),
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
                    selectedIndex: controller.activeNavigationBarIndex,
                    destinations: getNavigationDestinations(context),
                    onDestinationSelected: controller.onDestinationSelected,
                  ),
                ],
              ),
            );
          },
        )
      },
    );
  }

  Widget _primaryNavigationBarBuilder(BuildContext context) {
    final destinations = getNavigationDestinations(context);

    return AdaptiveScaffoldPrimaryNavigation(
      futureProfile: controller.fetchOwnProfile(),
      selectedIndex: controller.activeNavigationBar.value.index,
      getNavigationRailDestinations: destinations
          .map((_) => AdaptiveScaffold.toRailDestination(_))
          .toList(),
      onDestinationSelected: controller.onDestinationSelected,
      onSelected: (object) => controller.clientSelected(
        object,
        context,
      ),
    );
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.contacts_outlined),
        label: L10n.of(context)!.contacts,
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat),
        label: L10n.of(context)!.chat,
      ),
      NavigationDestination(
        icon: const Icon(Icons.web_stories_outlined),
        label: L10n.of(context)!.stories,
      ),
    ];
  }
}
