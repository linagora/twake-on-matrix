import 'package:fluffychat/config/inner_routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_view_style.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    hide WidgetBuilder;

class AppScaffoldView extends StatelessWidget {
  final List<AdaptiveDestinationEnum> destinations;
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;
  final OnOpenSearchPage onOpenSearchPage;
  final OnCloseSearchPage onCloseSearchPage;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final PageController pageController;

  final ValueNotifier<String?> activeRoomIdNotifier;

  static const ValueKey scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  const AppScaffoldView({
    Key? key,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.activeNavigationBar,
    required this.onOpenSearchPage,
    required this.onCloseSearchPage,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    final responsiveUtils = getIt.get<ResponsiveUtils>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (!responsiveUtils.isMobile(context)) ...[
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
                          case AdaptiveDestinationEnum.contacts:
                          case AdaptiveDestinationEnum.rooms:
                          default:
                            return _PrimaryNavigationBarBuilder(
                              activeNavigationBar: activeNavigationBar,
                              onDestinationSelected: onDestinationSelected,
                              onClientSelected: onClientSelected,
                              destinations: getNavigationDestinations(context),
                            );
                        }
                      },
                    );
                  },
                ),
              },
            ),
          ],
          if (responsiveUtils.isTwoColumnLayout(context)) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: AppScaffoldViewStyle.borderRadiusBody,
                child: Container(
                  decoration: BoxDecoration(
                    color: LinagoraRefColors.material().primary[100],
                  ),
                  child: Navigator(
                    key: InnerRoutes.innerNavigatorKey,
                    initialRoute: 'innernavigator/rooms',
                    onGenerateRoute: (settings) {
                      if (settings.name == 'innernavigator/rooms') {
                        return MaterialPageRoute(
                          builder: (context) {
                            return _ColumnPageView(
                              activeRoomIdNotifier: activeRoomIdNotifier,
                              activeNavigationBar: activeNavigationBar,
                              pageController: pageController,
                              onOpenSearchPage: onOpenSearchPage,
                              onCloseSearchPage: onCloseSearchPage,
                              onDestinationSelected: onDestinationSelected,
                              onClientSelected: onClientSelected,
                              destinations: destinations,
                              bottomNavigationKey: bottomNavigationKey,
                            );
                          },
                        );
                      } else {
                        return InnerRoutes.routes(
                          settings.name,
                          arguments: settings.arguments,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: _ColumnPageView(
                activeRoomIdNotifier: activeRoomIdNotifier,
                activeNavigationBar: activeNavigationBar,
                pageController: pageController,
                onOpenSearchPage: onOpenSearchPage,
                onCloseSearchPage: onCloseSearchPage,
                onDestinationSelected: onDestinationSelected,
                onClientSelected: onClientSelected,
                destinations: destinations,
                bottomNavigationKey: bottomNavigationKey,
              ),
            ),
          ]
        ],
      ),
    );
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    return destinations.map((destination) {
      return destination.getNavigationDestination(context);
    }).toList();
  }
}

class _ColumnPageView extends StatelessWidget {
  final List<AdaptiveDestinationEnum> destinations;
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;
  final PageController pageController;
  final OnOpenSearchPage onOpenSearchPage;
  final OnCloseSearchPage onCloseSearchPage;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final ValueKey bottomNavigationKey;
  final ValueNotifier<String?> activeRoomIdNotifier;

  const _ColumnPageView({
    required this.activeNavigationBar,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.onOpenSearchPage,
    required this.onCloseSearchPage,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
    required this.bottomNavigationKey,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _triggerPageViewBuilder(
          navigatorBarType: AdaptiveDestinationEnum.contacts,
          navigatorBarWidget: ContactsTab(
            bottomNavigationBar: _bottomNavigationBarBuilder(context),
          ),
        ),
        ChatList(
          bottomNavigationBar: _triggerPageViewBuilder(
            navigatorBarType: AdaptiveDestinationEnum.rooms,
            navigatorBarWidget: _bottomNavigationBarBuilder(context),
          ),
          onOpenSearchPage: onOpenSearchPage,
          activeRoomIdNotifier: activeRoomIdNotifier,
        ),
        _triggerPageViewBuilder(
          navigatorBarType: AdaptiveDestinationEnum.settings,
          navigatorBarWidget: Settings(
            bottomNavigationBar: _bottomNavigationBarBuilder(context),
          ),
        ),
        Search(
          onCloseSearchPage: onCloseSearchPage,
        ),
      ],
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
          end: ResponsiveUtils.minDesktopWidth,
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
        ),
      },
    );
  }

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    return destinations.map((destination) {
      return destination.getNavigationDestination(context);
    }).toList();
  }

  int _getActiveBottomNavigationBarIndex() {
    return destinations.indexOf(activeNavigationBar.value);
  }
}

class _PrimaryNavigationBarBuilder extends StatelessWidget {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;

  final OnDestinationSelected onDestinationSelected;

  final OnClientSelectedSetting onClientSelected;

  final List<NavigationDestination> destinations;

  const _PrimaryNavigationBarBuilder({
    required this.activeNavigationBar,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffoldPrimaryNavigation(
      selectedIndex: activeNavigationBar.value.index,
      getNavigationRailDestinations: destinations
          .map((_) => AdaptiveScaffold.toRailDestination(_))
          .toList(),
      onDestinationSelected: onDestinationSelected,
      onSelected: (object) => onClientSelected(object, context),
    );
  }
}
