import 'dart:async';

import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/presentation/enum/settings/settings_action_enum.dart';
import 'package:fluffychat/presentation/mixins/connect_page_mixin.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body_view.dart';
import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logout_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/receive_content_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/switch_active_account_body_args.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

typedef OnCloseSearchPage = void Function();
typedef OnClientSelectedSetting =
    void Function(Object object, BuildContext context);
typedef OnDestinationSelected = void Function(int index);
typedef OnPopInvoked = void Function(bool);

class AppAdaptiveScaffoldBody extends StatefulWidget {
  final AbsAppAdaptiveScaffoldBodyArgs? args;
  final String? activeRoomId;

  const AppAdaptiveScaffoldBody({
    super.key,
    required this.args,
    this.activeRoomId,
  });

  @override
  State<AppAdaptiveScaffoldBody> createState() =>
      AppAdaptiveScaffoldBodyController();
}

class AppAdaptiveScaffoldBodyController extends State<AppAdaptiveScaffoldBody>
    with ConnectPageMixin {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier =
      ValueNotifier<AdaptiveDestinationEnum>(AdaptiveDestinationEnum.rooms);

  final activeRoomIdNotifier = ValueNotifier<String?>(null);
  final currentProfileNotifier = ValueNotifier<Profile?>(Profile(userId: ''));
  StreamSubscription? onAccountDataSubscription;

  final PageController pageController = PageController(
    initialPage: 1,
    keepPage: true,
  );

  final responsiveUtils = ResponsiveUtils();

  List<AdaptiveDestinationEnum> get destinations => [
    AdaptiveDestinationEnum.contacts,
    AdaptiveDestinationEnum.rooms,
    AdaptiveDestinationEnum.settings,
  ];

  void onDestinationSelected(int index) {
    final destinationType = destinations[index];
    activeNavigationBarNotifier.value = destinationType;
    pageController.jumpToPage(index);
    clearNavigatorScreen();
  }

  void clearNavigatorScreen() {
    final navigatorContext = !responsiveUtils.isSingleColumnLayout(context)
        ? FirstColumnInnerRoutes.innerNavigatorNotOneColumnKey.currentContext
        : FirstColumnInnerRoutes.innerNavigatorOneColumnKey.currentContext;
    if (navigatorContext != null) {
      navigatorContext.popInnerAll();
    }
  }

  void clientSelected(Object object, BuildContext context) async {
    if (object is SettingsAction) {
      switch (object) {
        case SettingsAction.settings:
          _onOpenSettingsPage();
          break;
        case SettingsAction.archive:
        case SettingsAction.addAccount:
        case SettingsAction.newStory:
        case SettingsAction.newSpace:
        case SettingsAction.invite:
          break;
      }
    }
  }

  void _onOpenSettingsPage() {
    activeNavigationBarNotifier.value = AdaptiveDestinationEnum.settings;
    _jumpToPageByIndex();
  }

  void _jumpToPageByIndex() {
    pageController.jumpToPage(activeNavigationBarNotifier.value.index);
  }

  void _onPopInvoked(_) {
    if (!PlatformInfos.isAndroid) {
      return;
    }
    final inChatList =
        activeNavigationBarNotifier.value == AdaptiveDestinationEnum.rooms;
    if (inChatList) {
      return;
    } else {
      onDestinationSelected(AdaptiveDestinationEnum.rooms.index);
    }
  }

  void _handleLogout(AppAdaptiveScaffoldBody oldWidget) {
    activeNavigationBarNotifier.value = AdaptiveDestinationEnum.rooms;
    pageController.jumpToPage(AdaptiveDestinationEnum.rooms.index);
    getCurrentProfile();
    onAccountDataSubscription?.cancel();
    _handleProfileDataChange();
  }

  void _handleSwitchAccount(AppAdaptiveScaffoldBody oldWidget) {
    activeNavigationBarNotifier.value = AdaptiveDestinationEnum.rooms;
    pageController.jumpToPage(AdaptiveDestinationEnum.rooms.index);
    getCurrentProfile();
    onAccountDataSubscription?.cancel();
    _handleProfileDataChange();
  }

  void getCurrentProfile() async {
    final profile = await matrix.client.fetchOwnProfile(
      getFromRooms: false,
      cache: false,
    );
    currentProfileNotifier.value = profile;
  }

  void _handleProfileDataChange() {
    onAccountDataSubscription = matrix.client.onAccountData.stream.listen((
      event,
    ) {
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        getCurrentProfile();
      }
    });
  }

  void _handleReceiveContent(ReceiveContentArgs args) {
    if (args.activeDestination == null) return;
    if (args.activeDestination != AdaptiveDestinationEnum.rooms) {
      activeNavigationBarNotifier.value = AdaptiveDestinationEnum.rooms;
      pageController.jumpToPage(AdaptiveDestinationEnum.rooms.index);
    }
  }

  MatrixState get matrix => Matrix.of(context);

  @override
  void initState() {
    super.initState();
    activeRoomIdNotifier.value = widget.activeRoomId;
    resetLocationPathWithLoginToken();
    // Initial sharing intent is now handled in chat_list.dart after _trySync completes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await matrix.retrievePersistedActiveClient();
        getCurrentProfile();
        _handleProfileDataChange();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppAdaptiveScaffoldBody oldWidget) {
    activeRoomIdNotifier.value = widget.activeRoomId;
    Logs().d(
      'AppAdaptiveScaffoldBodyController::didUpdateWidget():oldWidget - ${oldWidget.args}',
    );
    Logs().d(
      'AppAdaptiveScaffoldBodyController::didUpdateWidget():newWidget - ${widget.args}',
    );
    if (oldWidget.args != widget.args && widget.args is LogoutBodyArgs) {
      _handleLogout(oldWidget);
    }

    if (oldWidget.args != widget.args &&
        widget.args is LoggedInOtherAccountBodyArgs) {
      getCurrentProfile();
      _handleProfileDataChange();
    }

    if (oldWidget.args != widget.args &&
        widget.args is SwitchActiveAccountBodyArgs) {
      _handleSwitchAccount(oldWidget);
    }

    if (oldWidget.args != widget.args && widget.args is ReceiveContentArgs) {
      _handleReceiveContent(widget.args as ReceiveContentArgs);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    activeRoomIdNotifier.dispose();
    activeNavigationBarNotifier.dispose();
    pageController.dispose();
    currentProfileNotifier.dispose();
    onAccountDataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppAdaptiveScaffoldBodyView(
    destinations: destinations,
    activeRoomIdNotifier: activeRoomIdNotifier,
    activeNavigationBarNotifier: activeNavigationBarNotifier,
    pageController: pageController,
    onDestinationSelected: onDestinationSelected,
    onClientSelected: clientSelected,
    onPopInvoked: _onPopInvoked,
    onOpenSettings: _onOpenSettingsPage,
    adaptiveScaffoldBodyArgs: widget.args,
    currentProfile: currentProfileNotifier,
  );
}
