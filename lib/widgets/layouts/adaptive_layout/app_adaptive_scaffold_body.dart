import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body_view.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

typedef OnOpenSearchPage = void Function();
typedef OnCloseSearchPage = void Function();
typedef OnClientSelectedSetting = void Function(
  Object object,
  BuildContext context,
);
typedef OnDestinationSelected = void Function(int index);
typedef OnPopInvoked = void Function(bool);

class AppAdaptiveScaffoldBody extends StatefulWidget {
  final String? activeRoomId;
  final Client? client;

  const AppAdaptiveScaffoldBody({
    super.key,
    this.activeRoomId,
    this.client,
  });

  @override
  State<AppAdaptiveScaffoldBody> createState() =>
      AppAdaptiveScaffoldBodyController();
}

class AppAdaptiveScaffoldBodyController extends State<AppAdaptiveScaffoldBody> {
  final ValueNotifier<AdaptiveDestinationEnum> activeNavigationBarNotifier =
      ValueNotifier<AdaptiveDestinationEnum>(AdaptiveDestinationEnum.rooms);

  final activeRoomIdNotifier = ValueNotifier<String?>(null);

  final PageController pageController =
      PageController(initialPage: 1, keepPage: true);

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

  void clientSelected(
    Object object,
    BuildContext context,
  ) async {
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

        default:
          break;
      }
    }
  }

  void _onOpenSettingsPage() {
    activeNavigationBarNotifier.value = AdaptiveDestinationEnum.settings;
    _jumpToPageByIndex();
  }

  void _onOpenSearchPage() {
    pageController.jumpToPage(AdaptiveDestinationEnum.search.index);
  }

  void _onCloseSearchPage() {
    activeNavigationBarNotifier.value = AdaptiveDestinationEnum.rooms;
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

  MatrixState get matrix => Matrix.of(context);

  @override
  void initState() {
    activeRoomIdNotifier.value = widget.activeRoomId;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AppAdaptiveScaffoldBody oldWidget) {
    activeRoomIdNotifier.value = widget.activeRoomId;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    activeRoomIdNotifier.dispose();
    activeNavigationBarNotifier.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppAdaptiveScaffoldBodyView(
        destinations: destinations,
        activeRoomIdNotifier: activeRoomIdNotifier,
        activeNavigationBarNotifier: activeNavigationBarNotifier,
        pageController: pageController,
        onOpenSearchPage: _onOpenSearchPage,
        onCloseSearchPage: _onCloseSearchPage,
        onDestinationSelected: onDestinationSelected,
        onClientSelected: clientSelected,
        onPopInvoked: _onPopInvoked,
        onOpenSettings: _onOpenSettingsPage,
        client: widget.client,
      );
}
