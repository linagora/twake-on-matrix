import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar_view.dart';
import 'package:fluffychat/presentation/enum/chat/media_viewer_popup_result_enum.dart';
import 'package:fluffychat/presentation/model/pop_result_from_forward.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

class MediaViewerAppBar extends StatefulWidget {
  const MediaViewerAppBar({
    Key? key,
    this.showAppbarPreviewNotifier,
    this.event,
  }) : super(key: key);

  final ValueNotifier<bool>? showAppbarPreviewNotifier;
  final Event? event;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  State<MediaViewerAppBar> createState() => MediaViewerAppBarController();
}

class MediaViewerAppBarController extends State<MediaViewerAppBar> {
  final MenuController menuController = MenuController();

  ValueNotifier<bool>? showAppbarPreview;

  final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  void initState() {
    super.initState();
    showAppbarPreview = widget.showAppbarPreviewNotifier;
  }

  @override
  void dispose() {
    super.dispose();
    showAppbarPreview?.dispose();
  }

  void toggleShowMoreActions() {
    if (menuController.isOpen) {
      menuController.close();
    } else {
      menuController.open();
    }
  }

  /// Forward this image to another room.
  void forwardAction() async {
    Matrix.of(context).shareContent = widget.event?.content;
    final result = await showDialog(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      builder: (c) => const Forward(),
    );
    if (result is PopResultFromForward) {
      Navigator.of(context).pop<PopResultFromForward>();
    }
  }

  void showInChat() {
    if (!PlatformInfos.isMobile) {
      handleShowInChatInWeb();
    } else {
      handleShowInChatInMobile();
    }
  }

  void handleShowInChatInWeb() {
    backToChatScreenInWeb();
    scrollToEventInChat();
    return;
  }

  void handleShowInChatInMobile() {
    backToChatScreenInMobile();
    scrollToEventInChat();
  }

  void backToChatScreenInWeb() {
    if (responsiveUtils.isTablet(context) ||
        responsiveUtils.isMobile(context)) {
      Navigator.of(context)
          .pop(MediaViewerPopupResultEnum.closeRightColumnFlag);
    } else {
      Navigator.of(context).pop();
    }
  }

  void scrollToEventInChat() {
    if (widget.event != null) {
      context.goToRoomWithEvent(widget.event!.room.id, widget.event!.eventId);
    }
  }

  void backToChatScreenInMobile() {
    Navigator.of(context).popUntil(
      (Route route) => route.settings.name == '/rooms/room',
    );
  }

  void onClose() {
    Navigator.of(context).pop();
  }

  void saveFileAction() => widget.event?.saveFile(context);

  void shareFileAction(BuildContext context) =>
      widget.event?.shareFile(context);

  @override
  Widget build(BuildContext context) {
    return MediaViewerAppbarView(this);
  }
}
