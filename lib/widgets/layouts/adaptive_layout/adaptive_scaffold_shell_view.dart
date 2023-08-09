import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_shell.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AppScaffoldShellView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  final AdaptiveScaffoldShellController controller;

  static const int roomsShellIndex = 1;

  static const ValueKey scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  static const ValueKey shellKey = ValueKey('Body');

  static const List<String> bottomNavigationAvailableList = [
    '/',
    '/rooms',
    '/contacts',
    '/stories',
  ];

  const AppScaffoldShellView({
    Key? key,
    required this.controller,
    required this.navigationShell,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdaptiveScaffoldAppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: WillPopScope(
        onWillPop: () async {
          if (navigationShell.currentIndex != roomsShellIndex) {
            navigationShell.goBranch(AdaptiveDestinationEnum.rooms.index);
          }
          return true;
        },
        child: AdaptiveLayout(
          body: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig>{
              const WidthPlatformBreakpoint(begin: 0): SlotLayout.from(
                key: shellKey,
                builder: (_) => navigationShell,
              ),
            },
          ),
          primaryNavigation: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig>{
              const WidthPlatformBreakpoint(
                begin: ResponsiveUtils.minDesktopWidth,
              ): SlotLayout.from(
                key: primaryNavigationKey,
                builder: (_) {
                  return AdaptiveScaffoldPrimaryNavigation(
                    controller: controller,
                    selectedIndex: _selectIndexPrimaryNavigation(),
                    getNavigationRailDestinations:
                        getNavigationDestinations(context)
                            .map((_) => AdaptiveScaffold.toRailDestination(_))
                            .toList(),
                    onDestinationSelected: onNavigationEvent,
                  );
                },
              )
            },
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationAvailable(context)
          ? SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.small: SlotLayout.from(
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
                            selectedIndex: navigationShell.currentIndex,
                            destinations: getNavigationDestinations(context),
                            onDestinationSelected: onNavigationEvent,
                          ),
                        ],
                      ),
                    );
                  },
                )
              },
            )
          : null,
    );
  }

  int _selectIndexPrimaryNavigation() {
    return navigationShell.currentIndex;
  }

  void onNavigationEvent(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool bottomNavigationAvailable(BuildContext context) {
    final path = GoRouterState.of(context).fullPath;
    if (path == null || path.isEmpty == true) {
      return true;
    } else {
      return bottomNavigationAvailableList
          .any((element) => path.endsWith(element));
    }
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    return [
      if (AppConfig.separateChatTypes) ...[
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
      ] else
        NavigationDestination(
          icon: const Icon(Icons.chat_outlined),
          label: L10n.of(context)!.chats,
        ),
    ];
  }
}
