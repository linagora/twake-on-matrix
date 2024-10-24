import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:matrix/matrix.dart';

class MessageStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double heightDivider = 1.0;
  static final bubbleBorderRadius = BorderRadius.circular(16);
  static final errorStatusPlaceHolderWidth = 16 * AppConfig.bubbleSizeFactor;
  static final errorStatusPlaceHolderHeight = 16 * AppConfig.bubbleSizeFactor;
  static const double avatarSize = 40;
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
  static const double messageBubbleMobileRatioMaxWidth = 0.80;
  static const double messageBubbleTabletRatioMaxWidth = 0.30;

  static double messageBubbleWidth(BuildContext context) {
    return context.responsiveValue<double>(
      desktop: messageBubbleDesktopMaxWidth,
      tablet: context.width * messageBubbleTabletRatioMaxWidth,
      mobile:
          MediaQuery.sizeOf(context).width * messageBubbleMobileRatioMaxWidth,
    );
  }

  static double messageSpacing(
    bool displayTime,
    Event? nextEvent,
    Event currentEvent,
  ) {
    // add spaces to messages only
    if (nextEvent == null ||
        displayTime ||
        nextEvent.type != EventTypes.Message) {
      return 0;
    }

    return currentEvent.senderId != nextEvent.senderId ? 8 : 4;
  }

  static EdgeInsets paddingDisplayName(Event event) => EdgeInsets.only(
        left: event.messageType == MessageTypes.Image ? 0 : 8.0,
        bottom: 4.0,
      );

  static EdgeInsets get paddingMessage =>
      const EdgeInsets.symmetric(vertical: 2.0);

  static EdgeInsets get paddingTimestamp => const EdgeInsets.only(
        left: 8.0,
        right: 4.0,
      );

  static EdgeInsets get paddingEditButton => EdgeInsets.only(
        top: 4.0 * AppConfig.bubbleSizeFactor,
      );

  static const EdgeInsets paddingAvatar = EdgeInsets.only(
    right: 8.0,
  );

  static EdgeInsetsDirectional paddingMessageContainer(
    bool displayTime,
    BuildContext context,
    Event? nextEvent,
    Event event,
    bool selected,
  ) {
    return EdgeInsetsDirectional.only(
      top: MessageStyle.messageSpacing(
        displayTime,
        nextEvent,
        event,
      ),
      end: selected || responsiveUtils.isDesktop(context) ? 8 : 0,
    );
  }

  static EdgeInsets paddingMessageContentBuilder(Event event) =>
      EdgeInsets.only(
        left: 8 * AppConfig.bubbleSizeFactor,
        right: 8 * AppConfig.bubbleSizeFactor,
        top: 8 * AppConfig.bubbleSizeFactor,
        bottom: event.timelineOverlayMessage
            ? 8 * AppConfig.bubbleSizeFactor
            : 0 * AppConfig.bubbleSizeFactor,
      );

  static EdgeInsets get paddingMessageTime => const EdgeInsets.only(
        left: 6,
        right: 8.0,
        bottom: 4.0,
      );

  static EdgeInsetsDirectional get paddingSwipeMessage =>
      const EdgeInsetsDirectional.symmetric(horizontal: 16.0);

  static EdgeInsetsDirectional get paddingDividerUnreadMessage =>
      const EdgeInsetsDirectional.only(top: 16.0);
  static const double pushpinIconSize = 14.0;

  static const double paddingAllPushpin = 0;
  static const Color borderColorReceivedBubble = Color(0xFFEBEDF0);
  static MainAxisAlignment messageAlignment(
    Event event,
    BuildContext context,
  ) =>
      responsiveUtils.isMobile(context) && event.isOwnMessage
          ? MainAxisAlignment.end
          : MainAxisAlignment.start;
}
