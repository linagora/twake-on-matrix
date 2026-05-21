import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/image_size_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MessageStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double heightDivider = 1.0;
  static const Radius bubbleRadius = Radius.circular(16);
  static const Radius bubbleGroupedRadius = Radius.circular(8);
  static const bubbleBorderRadius = BorderRadius.all(bubbleRadius);

  static BorderRadius groupedBubbleBorderRadius({
    required bool isOwnMessage,
    required bool hasSameSenderAbove,
    required bool hasSameSenderBelow,
  }) {
    final tailSideTop = hasSameSenderAbove ? bubbleGroupedRadius : bubbleRadius;
    final tailSideBottom = hasSameSenderBelow
        ? bubbleGroupedRadius
        : bubbleRadius;
    if (isOwnMessage) {
      return BorderRadius.only(
        topLeft: bubbleRadius,
        bottomLeft: bubbleRadius,
        topRight: tailSideTop,
        bottomRight: tailSideBottom,
      );
    }
    return BorderRadius.only(
      topRight: bubbleRadius,
      bottomRight: bubbleRadius,
      topLeft: tailSideTop,
      bottomLeft: tailSideBottom,
    );
  }

  static final errorStatusPlaceHolderWidth = 16 * AppConfig.bubbleSizeFactor;
  static final errorStatusPlaceHolderHeight = 16 * AppConfig.bubbleSizeFactor;
  static const double avatarSize = 36;
  static const double fontSize = 15;
  static const notSameSenderPadding = EdgeInsets.only(left: 8.0, bottom: 4);

  static const double buttonHeight = 66;

  static List<BoxShadow> boxShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              offset: Offset(0, 0),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.16),
              offset: Offset(0, 0),
              blurRadius: 96,
            ),
          ]
        : [];
  }

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : const Color.fromARGB(239, 36, 36, 36);
  }

  static int get messageFlexMobile => 7;

  static int get replyIconFlexMobile => 2;

  static TextStyle? displayTime(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.merge(
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 0.4,
        ),
      );

  static double get forwardContainerSize => 40.0;

  static Color? forwardColorBackground(context) =>
      Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08);

  static const double messageBubbleDesktopMaxWidth = 520.0;
  static const double messageBubbleMobileRatioMaxWidth = 0.88;
  static const double messageBubbleTabletRatioMaxWidth = 0.30;
  static const double iconContextMenuSize = 40;

  static double defaultMessageBubbleWidth(BuildContext context) {
    return context.responsiveValue<double>(
      desktop: messageBubbleDesktopMaxWidth,
      tablet: context.width * messageBubbleTabletRatioMaxWidth,
      mobile:
          MediaQuery.sizeOf(context).width * messageBubbleMobileRatioMaxWidth,
    );
  }

  static double messageBubbleWidth(
    BuildContext context, {
    Event? event,
    double? maxWidthScreen,
  }) {
    final defaultWidth = defaultMessageBubbleWidth(context);

    if (maxWidthScreen != null) {
      return maxWidthScreen - defaultWidth > 0
          ? defaultWidth - iconContextMenuSize
          : defaultWidth;
    }
    return defaultWidth;
  }

  static double messageBubbleWidthVideoCaption({
    required BuildContext context,
    required Event event,
    double? textWidth,
  }) {
    if (event.isCaptionModeOrReply() == true) {
      DisplayImageInfo? displayImageInfo = event
          .getOriginalResolution()
          ?.getDisplayImageInfo(context);

      final matrixFile = event.getMatrixFile();

      if (matrixFile != null && matrixFile.isSendingImageInMobile()) {
        final file = matrixFile as MatrixImageFile;
        displayImageInfo = Size(
          file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
          file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
        ).getDisplayImageInfo(context);
        return _calculateMediaBubbleWidth(
          displayImageInfo: displayImageInfo,
          textWidth: textWidth,
        );
      }
      displayImageInfo ??= DisplayImageInfo(
        size: Size(
          MessageContentStyle.imageWidth(context),
          MessageContentStyle.imageHeight(context),
        ),
        hasBlur: true,
      );
      if (event.isReplyEvent()) {
        return double.infinity;
      }
      if (matrixFile != null && matrixFile.isSendingImageInWeb()) {
        return _calculateMediaBubbleWidth(
          displayImageInfo: displayImageInfo,
          textWidth: textWidth,
        );
      }

      return _calculateMediaBubbleWidth(
        displayImageInfo: displayImageInfo,
        textWidth: textWidth,
      );
    }

    return messageBubbleWidth(context, event: event);
  }

  static double _calculateMediaBubbleWidth({
    required DisplayImageInfo displayImageInfo,
    double? textWidth,
  }) {
    if (textWidth != null && displayImageInfo.size.width < textWidth) {
      return MessageContentStyle.imageBubbleWidth(textWidth);
    }
    return MessageContentStyle.imageBubbleWidth(displayImageInfo.size.width);
  }

  static double messageBubbleWidthMediaCaption({
    required BuildContext context,
    required Event event,
    double? textWidth,
  }) {
    if (event.isCaptionModeOrReply() == true) {
      DisplayImageInfo? displayImageInfo = event
          .getOriginalResolution()
          ?.getDisplayImageInfo(context);

      final matrixFile = event.getMatrixFile();

      if (matrixFile != null && matrixFile.isSendingImageInMobile()) {
        final file = matrixFile as MatrixImageFile;
        displayImageInfo = Size(
          file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
          file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
        ).getDisplayImageInfo(context);
        return _calculateMediaBubbleWidth(
          displayImageInfo: displayImageInfo,
          textWidth: textWidth,
        );
      }
      displayImageInfo ??= DisplayImageInfo(
        size: Size(
          MessageContentStyle.imageWidth(context),
          MessageContentStyle.imageHeight(context),
        ),
        hasBlur: true,
      );
      if (matrixFile != null && matrixFile.isSendingImageInWeb()) {
        final file = matrixFile as MatrixImageFile;
        displayImageInfo = Size(
          file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
          file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
        ).getDisplayImageInfo(context);
        return _calculateMediaBubbleWidth(
          displayImageInfo: displayImageInfo,
          textWidth: textWidth,
        );
      }
      return _calculateMediaBubbleWidth(
        displayImageInfo: displayImageInfo,
        textWidth: textWidth,
      );
    }

    return messageBubbleWidth(context, event: event);
  }

  static double messageSpacing(
    bool displayTime,
    Event? nextEvent,
    Event currentEvent, {
    bool nextEventHasReaction = false,
  }) {
    if (nextEvent == null || displayTime) {
      return 0;
    }

    if (nextEvent.shouldHideRedactedEvent()) {
      return nextEventHasReaction ? 8 : 6;
    }

    if (nextEvent.type != EventTypes.Message) {
      return 0;
    }

    if (currentEvent.senderId == nextEvent.senderId) {
      return 0;
    }
    return nextEventHasReaction ? 8 : 6;
  }

  static EdgeInsets paddingDisplayName(Event event) =>
      const EdgeInsets.only(bottom: 4.0);

  static EdgeInsets get paddingMessage =>
      const EdgeInsets.symmetric(vertical: 1.0);

  static EdgeInsets get paddingTimestamp =>
      const EdgeInsets.only(left: 8.0, right: 4.0);

  static EdgeInsets get paddingEditButton =>
      EdgeInsets.only(top: 4.0 * AppConfig.bubbleSizeFactor);

  static const EdgeInsets paddingAvatar = EdgeInsets.only(right: 8.0);

  static EdgeInsetsDirectional paddingMessageContainer(
    bool displayTime,
    BuildContext context,
    Event? nextEvent,
    Event event,
    bool selected, {
    bool nextEventHasReaction = false,
  }) {
    final needsRightMenuGap =
        responsiveUtils.isDesktop(context) &&
        event.shouldDisplayContextMenuInRightBubble;
    final endPadding = selected || needsRightMenuGap ? 8.0 : 0.0;
    return EdgeInsetsDirectional.only(
      top: MessageStyle.messageSpacing(
        displayTime,
        nextEvent,
        event,
        nextEventHasReaction: nextEventHasReaction,
      ),
      end: endPadding,
    );
  }

  static EdgeInsets paddingMessageContentBuilder(Event event) =>
      EdgeInsets.only(
        left: 10 * AppConfig.bubbleSizeFactor,
        right: 10 * AppConfig.bubbleSizeFactor,
        top: 6 * AppConfig.bubbleSizeFactor,
        bottom: event.timelineOverlayMessage
            ? 8 * AppConfig.bubbleSizeFactor
            : 0 * AppConfig.bubbleSizeFactor,
      );

  static EdgeInsets get paddingMessageTime =>
      const EdgeInsets.only(left: 6, right: 8.0, bottom: 4.0);

  static EdgeInsetsDirectional get paddingSwipeMessage =>
      const EdgeInsetsDirectional.symmetric(horizontal: 16.0);

  static EdgeInsetsDirectional get paddingDividerUnreadMessage =>
      const EdgeInsetsDirectional.only(top: 16.0);
  static const double pushpinIconSize = 14.0;

  static const double paddingAllPushpin = 0;
  static const Color borderColorReceivedBubble = Color(0xFFE5ECF3);

  static MainAxisAlignment messageAlignment(
    Event event,
    BuildContext context,
  ) => responsiveUtils.isMobile(context) && event.isOwnMessage
      ? MainAxisAlignment.end
      : MainAxisAlignment.start;

  static CrossAxisAlignment messageCrossAxisAlignment(
    Event event,
    BuildContext context,
  ) {
    return event.shouldAlignOwnMessageInDifferentSide
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
  }

  static AlignmentGeometry messageAlignmentGeometry(
    Event event,
    BuildContext context,
  ) {
    if (responsiveUtils.enableRightAndLeftMessageAlignment(context)) {
      return event.isOwnMessage ? Alignment.topRight : Alignment.topLeft;
    }
    return Alignment.topLeft;
  }

  static double mediaContentWidth({
    required BuildContext context,
    required Event event,
    required double calculatedWidth,
  }) {
    if (event.isReplyEvent()) {
      return double.infinity;
    }
    return calculatedWidth;
  }
}
