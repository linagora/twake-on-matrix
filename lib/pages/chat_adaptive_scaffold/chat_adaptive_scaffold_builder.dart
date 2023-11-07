import 'dart:async';

import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class ChatAdaptiveScaffoldBuilder extends StatefulWidget {
  final Widget Function(ChatAdaptiveScaffoldBuilderController controller)
      bodyBuilder;
  final Widget Function(
    ChatAdaptiveScaffoldBuilderController controller, {
    required bool isInStack,
    required RightColumnType type,
  }) rightBuilder;
  const ChatAdaptiveScaffoldBuilder({
    super.key,
    required this.bodyBuilder,
    required this.rightBuilder,
  });

  @override
  State<ChatAdaptiveScaffoldBuilder> createState() =>
      ChatAdaptiveScaffoldBuilderController();
}

class ChatAdaptiveScaffoldBuilderController
    extends State<ChatAdaptiveScaffoldBuilder> {
  final rightColumnTypeNotifier = ValueNotifier(RightColumnType.none);
  final jumpToEventIdStream = StreamController<EventId>.broadcast();

  void jumpToEventId(String eventId) {
    jumpToEventIdStream.sink.add(eventId);
  }

  void hideRightColumn() {
    rightColumnTypeNotifier.value = RightColumnType.none;
  }

  void setRightColumnType(RightColumnType type) {
    rightColumnTypeNotifier.value = type;
  }

  @override
  void dispose() {
    jumpToEventIdStream.close();
    rightColumnTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const breakpoint = ResponsiveUtils.minTabletWidth +
        MessageStyle.messageBubbleDesktopMaxWidth;
    return ValueListenableBuilder(
      valueListenable: rightColumnTypeNotifier,
      builder: (context, rightColumnType, body) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: AdaptiveLayout(
            body: SlotLayout(
              config: {
                const WidthPlatformBreakpoint(
                  end: breakpoint,
                ): SlotLayout.from(
                  key: AppAdaptiveScaffold.breakpointMobileKey,
                  builder: (_) => Stack(
                    children: [
                      body!,
                      if (rightColumnType.isShown)
                        widget.rightBuilder(
                          this,
                          isInStack: true,
                          type: rightColumnType,
                        ),
                    ],
                  ),
                ),
                const WidthPlatformBreakpoint(
                  begin: breakpoint,
                ): SlotLayout.from(
                  key: AppAdaptiveScaffold.breakpointWebAndDesktopKey,
                  builder: (_) => Padding(
                    padding: rightColumnType.isShown
                        ? ChatAdaptiveScaffoldStyle.webPaddingRight
                        : EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: ChatAdaptiveScaffoldStyle.borderRadius,
                      child: body!,
                    ),
                  ),
                ),
              },
            ),
            bodyRatio: 0.7,
            internalAnimations: false,
            secondaryBody: rightColumnType.isShown
                ? SlotLayout(
                    config: {
                      const WidthPlatformBreakpoint(
                        end: breakpoint,
                      ): SlotLayout.from(
                        key: AppAdaptiveScaffold.breakpointMobileKey,
                        builder: null,
                      ),
                      const WidthPlatformBreakpoint(
                        begin: breakpoint,
                      ): SlotLayout.from(
                        key: AppAdaptiveScaffold.breakpointWebAndDesktopKey,
                        builder: (_) => ClipRRect(
                          borderRadius: ChatAdaptiveScaffoldStyle.borderRadius,
                          child: widget.rightBuilder(
                            this,
                            isInStack: false,
                            type: rightColumnType,
                          ),
                        ),
                      ),
                    },
                  )
                : null,
          ),
        );
      },
      child: widget.bodyBuilder(this),
    );
  }
}

enum RightColumnType {
  none,
  search,
  chatDirectDetails,
}

extension RightColumnTypeExtension on RightColumnType {
  bool get isShown => this != RightColumnType.none;

  String? get initialRoute => ({
        RightColumnType.search: RightColumnRouteNames.search,
        RightColumnType.chatDirectDetails:
            RightColumnRouteNames.chatDirectDetails,
      })[this];
}

class RightColumnRouteNames {
  static const search = 'rightColumn/search';
  static const chatDirectDetails = 'rightColumn/chatDirectDetails';
}
