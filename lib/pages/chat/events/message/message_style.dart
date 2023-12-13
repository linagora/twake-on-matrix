import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matrix/matrix.dart';

class MessageStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static final bubbleBorderRadius = BorderRadius.circular(20.0.r);
  static double avatarSize = 40.0.w;
  static double fontSize = 15.0.sp;

  static int get replyIconFlexMobile => 2;

  static double get forwardContainerSize => 40.0.w;

  static Color? forwardColorBackground(context) =>
      Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08);

  static double messageBubbleDesktopMaxWidth = 520.0.w;
  static double messageBubbleMobileRatioMaxWidth = 0.80.w;
  static double messageBubbleTabletRatioMaxWidth = 0.30.w;

  static double messageBubbleWidth(BuildContext context) {
    return (context.responsiveValue<double>(
      desktop: messageBubbleDesktopMaxWidth,
      tablet: context.width * messageBubbleTabletRatioMaxWidth,
      mobile:
          MediaQuery.of(context).size.width * messageBubbleMobileRatioMaxWidth,
    )).w;
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

    return (currentEvent.senderId != nextEvent.senderId ? 8 : 4).h;
  }

  static EdgeInsets paddingDisplayName(Event event) => EdgeInsets.only(
        left: event.messageType == MessageTypes.Image ? 0 : 8.0.w,
        bottom: 4.0.h,
      );

  static EdgeInsets get paddingTimestamp => EdgeInsets.only(
        left: 8.0.w,
        right: 4.0.w,
      );

  static EdgeInsets get paddingEditButton => EdgeInsets.only(
        top: (4.0 * AppConfig.bubbleSizeFactor).h,
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
      start: 8.0.w,
      end: (selected || responsiveUtils.isDesktop(context) ? 8 : 0).w,
    );
  }

  static EdgeInsets paddingMessageContentBuilder(Event event) =>
      EdgeInsets.only(
        left: (8 * AppConfig.bubbleSizeFactor).w,
        right: (8 * AppConfig.bubbleSizeFactor).w,
        top: (8 * AppConfig.bubbleSizeFactor).h,
        bottom: (event.timelineOverlayMessage
                ? 8 * AppConfig.bubbleSizeFactor
                : 0 * AppConfig.bubbleSizeFactor)
            .h,
      );

  static EdgeInsets get paddingMessageTime => EdgeInsets.only(
        left: 6.0.w,
        right: 8.0.w,
        bottom: 4.0.h,
      );

  static EdgeInsetsDirectional get paddingSwipeMessage =>
      EdgeInsetsDirectional.symmetric(horizontal: 12.0.w);
}
