import 'dart:async';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_style.dart';
import 'package:fluffychat/pages/chat_direct_details/chat_direct_details.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:matrix/matrix.dart';

class ChatAdaptiveScaffold extends StatefulWidget {
  final String roomId;
  final MatrixFile? shareFile;
  final String? roomName;

  const ChatAdaptiveScaffold({
    Key? key,
    required this.roomId,
    this.shareFile,
    this.roomName,
  }) : super(key: key);

  @override
  State<ChatAdaptiveScaffold> createState() => ChatAdaptiveScaffoldController();
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

class ChatAdaptiveScaffoldController extends State<ChatAdaptiveScaffold> {
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
                        _RightColumnNavigator(
                          controller: this,
                          initialRoute: rightColumnType.initialRoute,
                          isInStack: true,
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
                          child: _RightColumnNavigator(
                            controller: this,
                            isInStack: false,
                            initialRoute: rightColumnType.initialRoute,
                          ),
                        ),
                      ),
                    },
                  )
                : null,
          ),
        );
      },
      child: Chat(
        roomId: widget.roomId,
        shareFile: widget.shareFile,
        roomName: widget.roomName,
        onChangeRightColumnType: setRightColumnType,
        jumpToEventIdStream: jumpToEventIdStream,
      ),
    );
  }
}

class _RightColumnNavigator extends StatelessWidget {
  final ChatAdaptiveScaffoldController controller;
  final bool isInStack;
  final String? initialRoute;

  const _RightColumnNavigator({
    required this.controller,
    required this.isInStack,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RightColumnRouteNames.search:
            return MaterialPageRoute(
              builder: (_) => ChatSearch(
                roomId: controller.widget.roomId,
                onBack: controller.hideRightColumn,
                jumpToEventId: controller.jumpToEventId,
                isInStack: isInStack,
              ),
            );
          case RightColumnRouteNames.chatDirectDetails:
            return MaterialPageRoute(
              builder: (_) => const ChatDirectDetails(),
            );
        }
        return MaterialPageRoute(builder: (_) => const SizedBox());
      },
    );
  }
}
