import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';
import 'package:twake_chat/pages/chat_list/browse_public_groups_button.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import 'package:twake_chat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    hide WidgetBuilder;
import 'package:matrix/matrix.dart';

class AppAdaptiveScaffoldBodyView extends StatelessWidget {
  final List<AdaptiveDestinationEnum> destinations;
  final List<AdaptiveDestinationEnum> barDestinations;
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final PageController pageController;
  final OnPopInvoked onPopInvoked;
  final VoidCallback onOpenSettings;
  final ValueNotifier<bool>? searchOpen;
  final TextEditingController? searchQuery;
  final AbsAppAdaptiveScaffoldBodyArgs? adaptiveScaffoldBodyArgs;
  final ValueNotifier<Profile?> currentProfile;
  final ValueNotifier<String?> activeRoomIdNotifier;

  const AppAdaptiveScaffoldBodyView({
    super.key,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.activeNavigationBarNotifier,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
    required this.barDestinations,
    required this.onPopInvoked,
    required this.onOpenSettings,
    this.searchOpen,
    this.searchQuery,
    this.adaptiveScaffoldBodyArgs,
    required this.currentProfile,
  });

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
            // ignore: deprecated_member_use
            onPopInvoked: onPopInvoked,
            child: Row(
              children: [
                if (!responsiveUtils.isMobile(context)) ...[
                  SlotLayout(
                    config: <Breakpoint, SlotLayoutConfig>{
                      const WidthPlatformBreakpoint(
                        begin: ResponsiveUtils.minDesktopWidth,
                      ): SlotLayout.from(
                        key: NavigationKeys.primaryNavigation.valueKey,
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
                                    selectedIndex: destinations.indexOf(
                                      navigatorBar,
                                    ),
                                    destinations: getNavigationDestinations(
                                      context,
                                    ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: LinagoraRefColors.material().primary[100],
                      ),
                      child: Navigator(
                        key: !responsiveUtils.isSingleColumnLayout(context)
                            ? FirstColumnInnerRoutes
                                  .innerNavigatorNotOneColumnKey
                            : FirstColumnInnerRoutes.innerNavigatorOneColumnKey,
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
                                  onDestinationSelected: onDestinationSelected,
                                  onClientSelected: onClientSelected,
                                  destinations: destinations,
                                  barDestinations: barDestinations,
                                  onOpenSettings: onOpenSettings,
                                  searchOpen: searchOpen,
                                  searchQuery: searchQuery,
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
                ] else ...[
                  Expanded(
                    child: _ColumnPageView(
                      activeRoomIdNotifier: activeRoomIdNotifier,
                      activeNavigationBarNotifier: activeNavigationBarNotifier,
                      pageController: pageController,
                      onDestinationSelected: onDestinationSelected,
                      onClientSelected: onClientSelected,
                      destinations: destinations,
                      barDestinations: barDestinations,
                      onOpenSettings: onOpenSettings,
                      searchOpen: searchOpen,
                      searchQuery: searchQuery,
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
      return destination.getNavigationDestination(context, currentProfile);
    }).toList();
  }
}

class _ColumnPageView extends StatelessWidget {
  final List<AdaptiveDestinationEnum> destinations;
  final List<AdaptiveDestinationEnum> barDestinations;
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier;
  final PageController pageController;
  final OnDestinationSelected onDestinationSelected;
  final OnClientSelectedSetting onClientSelected;
  final ValueNotifier<String?> activeRoomIdNotifier;
  final VoidCallback onOpenSettings;
  final ValueNotifier<bool>? searchOpen;
  final TextEditingController? searchQuery;
  final AbsAppAdaptiveScaffoldBodyArgs? adaptiveScaffoldBodyArgs;

  const _ColumnPageView({
    required this.activeNavigationBarNotifier,
    required this.activeRoomIdNotifier,
    required this.pageController,
    required this.onDestinationSelected,
    required this.onClientSelected,
    required this.destinations,
    required this.barDestinations,
    required this.onOpenSettings,
    required this.searchOpen,
    required this.searchQuery,
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
            navigatorBarWidget: _bottomNavigationBarBuilder(
              context,
              withSearch: true,
            ),
          ),
          activeRoomIdNotifier: activeRoomIdNotifier,
          onOpenSettings: onOpenSettings,
          adaptiveScaffoldBodyArgs: adaptiveScaffoldBodyArgs,
          searchOpen: searchOpen,
          searchResults: Search(
            embedded: true,
            textEditingController: searchQuery,
          ),
        ),
        if (destinations.contains(AdaptiveDestinationEnum.activity))
          _triggerPageViewBuilder(
            navigatorBarType: AdaptiveDestinationEnum.activity,
            navigatorBarWidget: ActivityPage(
              bottomNavigationBar: _bottomNavigationBarBuilder(context),
            ),
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

  /// [withSearch]: the bar of the Chats tab, with its search button.
  Widget _bottomNavigationBarBuilder(
    BuildContext context, {
    bool withSearch = false,
  }) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          end: ResponsiveUtils.minDesktopWidth,
        ): SlotLayout.from(
          key: NavigationKeys.bottomNavigation.valueKey,
          builder: (context) {
            // The search of the bar is the phone's: wider, the header keeps
            // its field.
            final search = withSearch && ResponsiveUtils().isMobile(context);
            return FloatingNavigationBar(
              destinations: barDestinations,
              selected: activeNavigationBarNotifier.value,
              onDestinationSelected: (index) => onDestinationSelected(
                destinations.indexOf(barDestinations[index]),
              ),
              searchOpen: search ? searchOpen : null,
              searchQuery: search ? searchQuery : null,
              searchSuffix: search ? const BrowsePublicGroupsButton() : null,
            );
          },
        ),
      },
    );
  }
}

class _PrimaryNavigationBarBuilder extends StatelessWidget {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBar;

  final OnDestinationSelected onDestinationSelected;

  final int selectedIndex;

  final List<NavigationDestination> destinations;

  const _PrimaryNavigationBarBuilder({
    required this.activeNavigationBar,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffoldPrimaryNavigation(
      selectedIndex: selectedIndex,
      getNavigationRailDestinations: destinations
          .map((destination) => AdaptiveScaffold.toRailDestination(destination))
          .toList(),
      onDestinationSelected: onDestinationSelected,
    );
  }
}
