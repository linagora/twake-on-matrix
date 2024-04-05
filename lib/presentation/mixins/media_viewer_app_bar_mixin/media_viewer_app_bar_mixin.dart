import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/presentation/mixins/media_viewer_app_bar_mixin/media_viewer_app_bar_mixin_style.dart';
import 'package:fluffychat/presentation/model/pop_result_from_forward.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

mixin MediaViewerAppBarMixin {
  final MenuController menuController = MenuController();

  final responsiveUtils = getIt.get<ResponsiveUtils>();

  void toggleShowMoreActions(MenuController menuController) {
    if (menuController.isOpen) {
      menuController.close();
    } else {
      menuController.open();
    }
  }

  /// Forward this image to another room.
  void forwardAction(
    BuildContext context,
    Event? event,
  ) async {
    Matrix.of(context).shareContent = event?.content;
    final responsive = getIt.get<ResponsiveUtils>();

    final result = responsive.isMobile(context)
        ? await _showForwardMobileDialog(context)
        : await _showForwardWebDialog(context);

    if (result is PopResultFromForward) {
      Navigator.of(context).pop<PopResultFromForward>();
    }
  }

  Future<PopResultFromForward?> _showForwardMobileDialog(
    BuildContext context,
  ) async =>
      await showDialog(
        context: context,
        useSafeArea: false,
        useRootNavigator: false,
        builder: (c) => const Forward(),
      );

  Future<PopResultFromForward?> _showForwardWebDialog(
    BuildContext context,
  ) async =>
      await showDialog(
        context: context,
        useRootNavigator: false,
        builder: (c) => AlertDialog(
          backgroundColor: LinagoraRefColors.material().primary[100],
          surfaceTintColor: LinagoraRefColors.material().primary[100],
          content: const SizedBox(
            width: MediaViewerAppBarMixinStyle.fixedForwardActionDialogWidth,
            height: MediaViewerAppBarMixinStyle.fixedForwardActionDialogHeight,
            child: Forward(),
          ),
        ),
      );

  void showInChat(
    BuildContext context,
    Event? event,
  ) {
    if (!PlatformInfos.isMobile) {
      handleShowInChatInWeb(context, event);
    } else {
      handleShowInChatInMobile(context, event);
    }
  }

  void handleShowInChatInWeb(
    BuildContext context,
    Event? event,
  ) {
    backToChatScreenInWeb(context, event);
    scrollToEventInChat(context, event);
    return;
  }

  void handleShowInChatInMobile(
    BuildContext context,
    Event? event,
  ) {
    backToChatScreenInMobile(context);
    scrollToEventInChat(context, event);
  }

  void backToChatScreenInWeb(
    BuildContext context,
    Event? event,
  ) {
    if (responsiveUtils.isTablet(context) ||
        responsiveUtils.isMobile(context)) {
      Navigator.of(context)
          .pop(MediaViewerPopupResultEnum.closeRightColumnFlag);
    } else {
      Navigator.of(context).pop();
    }
  }

  void scrollToEventInChat(
    BuildContext context,
    Event? event,
  ) {
    if (event != null) {
      context.goToRoomWithEvent(event.room.id, event.eventId);
    }
  }

  void backToChatScreenInMobile(BuildContext context) {
    Navigator.of(context).popUntil(
      (Route route) => route.settings.name == '/rooms/room',
    );
  }

  void onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void saveFileAction(
    BuildContext context,
    Event? event,
  ) =>
      event?.saveFile(context);

  void shareFileAction(
    BuildContext context,
    Event? event,
  ) =>
      event?.shareFile(context);
}
