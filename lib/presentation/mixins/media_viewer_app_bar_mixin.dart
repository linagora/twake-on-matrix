import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/pages/forward/forward.dart';
import 'package:twake_chat/pages/forward/forward_web_view.dart';
import 'package:twake_chat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:twake_chat/presentation/mixins/save_media_to_gallery_android_mixin.dart';
import 'package:twake_chat/presentation/model/pop_result_from_forward.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

mixin MediaViewerAppBarMixin on SaveMediaToGalleryAndroidMixin {
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
  void forwardAction(BuildContext context, Event? event) async {
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
  ) async => await showDialog(
    context: context,
    useSafeArea: false,
    useRootNavigator: false,
    builder: (c) => const Forward(),
  );

  final forwardSelectionMobileAndTabletKey =
      ChatKeys.forwardSelectionMobileAndTablet.key;

  final forwardSelectionWebAndDesktopKey =
      ChatKeys.forwardSelectionWebAndDesktop.key;

  Future<PopResultFromForward?> _showForwardWebDialog(
    BuildContext context,
  ) async => await showDialog(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    useRootNavigator: false,
    builder: (context) {
      return SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          const WidthPlatformBreakpoint(
            begin: ResponsiveUtils.minTabletWidth,
          ): SlotLayout.from(
            key: forwardSelectionWebAndDesktopKey,
            builder: (_) => const ForwardWebView(),
          ),
          const WidthPlatformBreakpoint(
            end: ResponsiveUtils.minTabletWidth,
          ): SlotLayout.from(
            key: forwardSelectionMobileAndTabletKey,
            builder: (_) => const Forward(),
          ),
        },
      );
    },
  );

  void showInChat(BuildContext context, Event? event) {
    if (!PlatformInfos.isMobile) {
      handleShowInChatInWeb(context, event);
    } else {
      handleShowInChatInMobile(context, event);
    }
  }

  void handleShowInChatInWeb(BuildContext context, Event? event) {
    backToChatScreenInWeb(context, event);
    scrollToEventInChat(context, event);
    return;
  }

  void handleShowInChatInMobile(BuildContext context, Event? event) {
    backToChatScreenInMobile(context);
    scrollToEventInChat(context, event);
  }

  void backToChatScreenInWeb(BuildContext context, Event? event) {
    if (responsiveUtils.isTablet(context) ||
        responsiveUtils.isMobile(context)) {
      Navigator.of(
        context,
      ).pop(MediaViewerPopupResultEnum.closeRightColumnFlag);
    } else {
      Navigator.of(context).pop();
    }
  }

  void scrollToEventInChat(BuildContext context, Event? event) {
    if (event != null) {
      context.goToRoomWithEvent(event.room.id, event.eventId);
    }
  }

  void backToChatScreenInMobile(BuildContext context) {
    Navigator.of(context).popUntil(
      (Route route) => route.settings.name?.startsWith('/rooms/') ?? false,
    );
  }

  void onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  void saveFileAction(BuildContext context, Event? event) {
    if (PlatformInfos.isWeb) {
      event?.saveFile(context);
    } else {
      if (event != null) {
        saveSelectedEventToGallery(context, event);
      }
    }
  }

  void shareFileAction(BuildContext context, Event? event) =>
      event?.shareFile(context);
}
