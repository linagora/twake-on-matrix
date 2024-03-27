import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_view_style.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body_view_style.dart';
import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    hide WidgetBuilder;

class AppAdaptiveScaffoldBodyView extends StatelessWidget {
  final List<AdaptiveDestinationEnum> destinations;
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final PageController pageController;
  final OnPopInvoked onPopInvoked;
  final VoidCallback onOpenSettings;
  final AbsAppAdaptiveScaffoldBodyArgs? adaptiveScaffoldBodyArgs;

  final ValueNotifier<String?> activeRoomIdNotifier;

  static const ValueKey scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const ValueKey bottomNavigationKey = ValueKey('BottomNavigation');

  static const ValueKey primaryNavigationKey =
      ValueKey('AdaptiveScaffoldPrimaryNavigation');

  const AppAdaptiveScaffoldBodyView({
    Key? key,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.activeNavigationBarNotifier,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
    required this.onPopInvoked,
    required this.onOpenSettings,
    this.adaptiveScaffoldBodyArgs,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    final responsiveUtils = getIt.get<ResponsiveUtils>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ValueListenableBuilder(
        valueListenable: activeNavigationBarNotifier,
        builder: (context, activeNavigationBar, __) {
          return PopScope(
            canPop: activeNavigationBar == AdaptiveDestinationEnum.rooms,
            onPopInvoked: onPopInvoked,
            child: Row(
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
                            valueListenable: activeNavigationBarNotifier,
                            builder: (_, navigatorBar, child) {
                              switch (navigatorBar) {
                                case AdaptiveDestinationEnum.contacts:
                                case AdaptiveDestinationEnum.rooms:
                                default:
                                  return _PrimaryNavigationBarBuilder(
                                    activeNavigationBar:
                                        activeNavigationBarNotifier,
                                    onDestinationSelected:
                                        onDestinationSelected,
                                    destinations:
                                        getNavigationDestinations(context),
                                  );
                              }
                            },
                          );
                        },
                      ),
                    },
                  ),
                ],
                if (!FirstColumnInnerRoutes.instance
                    .goRouteAvailableInFirstColumn()) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppScaffoldViewStyle.borderRadiusBody,
                      child: Container(
                        decoration: BoxDecoration(
                          color: LinagoraRefColors.material().primary[100],
                        ),
                        child: Navigator(
                          key: !responsiveUtils.isSingleColumnLayout(context)
                              ? FirstColumnInnerRoutes
                                  .innerNavigatorNotOneColumnKey
                              : FirstColumnInnerRoutes
                                  .innerNavigatorOneColumnKey,
                          initialRoute: 'innernavigator/rooms',
                          onGenerateRoute: (settings) {
                            if (settings.name == 'innernavigator/rooms') {
                              return MaterialPageRoute(
                                builder: (context) {
                                  return _ColumnPageView(
                                    activeRoomIdNotifier: activeRoomIdNotifier,
                                    activeNavigationBarNotifier:
                                        activeNavigationBarNotifier,
                                    pageController: pageController,
                                    onDestinationSelected:
                                        onDestinationSelected,
                                    onClientSelected: onClientSelected,
                                    destinations: destinations,
                                    bottomNavigationKey: bottomNavigationKey,
                                    onOpenSettings: onOpenSettings,
                                    adaptiveScaffoldBodyArgs:
                                        adaptiveScaffoldBodyArgs,
                                  );
                                },
                              );
                            } else {
                              return FirstColumnInnerRoutes.routes(
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
                      activeNavigationBarNotifier: activeNavigationBarNotifier,
                      pageController: pageController,
                      onDestinationSelected: onDestinationSelected,
                      onClientSelected: onClientSelected,
                      destinations: destinations,
                      bottomNavigationKey: bottomNavigationKey,
                      onOpenSettings: onOpenSettings,
                      adaptiveScaffoldBodyArgs: adaptiveScaffoldBodyArgs,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier;
  final PageController pageController;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final ValueKey bottomNavigationKey;
  final ValueNotifier<String?> activeRoomIdNotifier;
  final VoidCallback onOpenSettings;
  final AbsAppAdaptiveScaffoldBodyArgs? adaptiveScaffoldBodyArgs;

  const _ColumnPageView({
    required this.activeNavigationBarNotifier,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
    required this.bottomNavigationKey,
    required this.onOpenSettings,
    required this.adaptiveScaffoldBodyArgs,
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
          activeRoomIdNotifier: activeRoomIdNotifier,
          onOpenSettings: onOpenSettings,
          adaptiveScaffoldBodyArgs: adaptiveScaffoldBodyArgs,
        ),
        _triggerPageViewBuilder(
          navigatorBarType: AdaptiveDestinationEnum.settings,
          navigatorBarWidget: Settings(
            bottomNavigationBar: _bottomNavigationBarBuilder(context),
          ),
        ),
      ],
    );
  }

  Widget _triggerPageViewBuilder({
    required AdaptiveDestinationEnum navigatorBarType,
    required Widget navigatorBarWidget,
  }) {
    return ValueListenableBuilder<AdaptiveDestinationEnum>(
      valueListenable: activeNavigationBarNotifier,
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
              color: LinagoraSysColors.material().surface,
              padding: AppAdaptiveScaffoldBodyViewStyle.paddingBottomNavigation,
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NavigationBar(
                    backgroundColor: LinagoraSysColors.material().surface,
                    elevation: AppAdaptiveScaffoldBodyViewStyle.elevation,
                    height: ResponsiveUtils.heightBottomNavigationBar,
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
    return destinations.indexOf(activeNavigationBarNotifier.value);
  }
}

class _PrimaryNavigationBarBuilder extends StatelessWidget {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;

  final OnDestinationSelected onDestinationSelected;

  final List<NavigationDestination> destinations;

  const _PrimaryNavigationBarBuilder({
    required this.activeNavigationBar,
    required this.onDestinationSelected,
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
    );
  }
}
