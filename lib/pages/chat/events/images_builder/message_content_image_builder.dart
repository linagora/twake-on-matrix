import 'package:fluffychat/pages/chat/events/images_builder/image_bubble.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat/events/images_builder/sending_image_info_widget.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/extension/image_size_extension.dart';

class MessageImageBuilder extends StatelessWidget {
  final Event event;

  final void Function()? onTapPreview;

  final void Function()? onTapSelectMode;

  const MessageImageBuilder({
    super.key,
    required this.event,
    this.onTapPreview,
    this.onTapSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final matrixFile = event.getMatrixFile();

    DisplayImageInfo? displayImageInfo =
        event.getOriginalResolution()?.getDisplayImageInfo(context);

    if (isSendingImageInMobile(matrixFile)) {
      final file = matrixFile as MatrixImageFile;
      displayImageInfo = Size(
        file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
        file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
      ).getDisplayImageInfo(context);
      return SendingImageInfoWidget(
        key: ValueKey(event.eventId),
        matrixFile: file,
        event: event,
        onTapPreview: onTapPreview,
        displayImageInfo: displayImageInfo,
      );
    }
    displayImageInfo ??= DisplayImageInfo(
      size: Size(
        MessageContentStyle.imageWidth(context),
        MessageContentStyle.imageHeight(context),
      ),
      hasBlur: true,
    );
    if (isSendingImageInWeb(matrixFile)) {
      final file = matrixFile as MatrixImageFile;
      displayImageInfo = Size(
        file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
        file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
      ).getDisplayImageInfo(context);
      return SendingImageInfoWidget(
        key: ValueKey(event.eventId),
        matrixFile: file,
        event: event,
        onTapPreview: onTapPreview,
        displayImageInfo: displayImageInfo,
      );
    }
    return ImageBubble(
      event,
      width: displayImageInfo.size.width,
      height: displayImageInfo.size.height,
      fit: BoxFit.cover,
      onTapSelectMode: onTapSelectMode,
      onTapPreview: onTapPreview,
      animated: true,
      thumbnailOnly: true,
    );
  }

  bool isSendingImageInWeb(MatrixFile? matrixFile) {
    return matrixFile != null &&
        matrixFile.bytes != null &&
        matrixFile is MatrixImageFile;
  }

  bool isSendingImageInMobile(MatrixFile? matrixFile) {
    return matrixFile != null &&
        matrixFile.filePath != null &&
        matrixFile is MatrixImageFile &&
        !PlatformInfos.isWeb;
  }
}
