import 'package:flutter/widgets.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';

typedef ImageSize = Size;

extension DisplayImageInfoExtension on ImageSize {
  DisplayImageInfo getDisplayImageInfo(BuildContext context) {
    Size displayImageSize = Size(
      MessageContentStyle.imageWidth(context),
      MessageContentStyle.imageHeight(context),
    );
    displayImageSize = _getDisplaySizeForImage(
      width.toDouble(),
      height.toDouble(),
      context: context,
    );
    bool hasBlur = false;
    if (displayImageSize.width < MessageContentStyle.imageBubbleMinWidth ||
        displayImageSize.height < MessageContentStyle.imageBubbleMinHeight) {
      hasBlur = true;
    }
    return DisplayImageInfo(size: displayImageSize, hasBlur: hasBlur);
  }

  Size _getDisplaySizeForImage(
    double width,
    double height, {
    required BuildContext context,
  }) {
    double displayHeight = MessageContentStyle.imageHeight(context);
    double displayWidth = MessageContentStyle.imageWidth(context);
    if (height == 0 || width == 0) {
      return Size(displayWidth, displayHeight);
    }
    final ratio = width / height;

    if (width < height) {
      displayHeight = MessageContentStyle.imageBubbleDefaultHeight;
      displayWidth = displayHeight * ratio;
    } else {
      displayWidth = MessageContentStyle.imageBubbleDefaultWidth;
      displayHeight = displayWidth / ratio;
    }
    return Size(displayWidth, displayHeight);
  }
}
