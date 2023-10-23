import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
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
  State<ChatAdaptiveScaffold> createState() => _ChatAdaptiveScaffoldState();
}

class _ChatAdaptiveScaffoldState extends State<ChatAdaptiveScaffold> {
  final showRightPanelNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    const breakpoint = ResponsiveUtils.minTabletWidth +
        MessageStyle.messageBubbleDesktopMaxWidth;
    return ValueListenableBuilder(
      valueListenable: showRightPanelNotifier,
      builder: (context, showRightPanel, body) {
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
                      if (showRightPanel)
                        ChatSearch(
                          roomId: widget.roomId,
                          onBack: showRightPanelNotifier.toggle,
                        ),
                    ],
                  ),
                ),
                const WidthPlatformBreakpoint(
                  begin: breakpoint,
                ): SlotLayout.from(
                  key: AppAdaptiveScaffold.breakpointWebAndDesktopKey,
                  builder: (_) => Padding(
                    padding: showRightPanel
                        ? const EdgeInsetsDirectional.only(end: 16)
                        : EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: body!,
                    ),
                  ),
                ),
              },
            ),
            bodyRatio: 0.7,
            internalAnimations: false,
            secondaryBody: showRightPanel
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
                          borderRadius: BorderRadius.circular(16),
                          child: ChatSearch(
                            roomId: widget.roomId,
                            onBack: showRightPanelNotifier.toggle,
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
        toggleRightPanel: () => showRightPanelNotifier.toggle(),
      ),
    );
  }
}
