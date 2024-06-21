import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_style.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

typedef ChatAdaptiveScaffoldBodyBuilder = Widget Function(
  ChatAdaptiveScaffoldBuilderController controller,
);

typedef ChatAdaptiveScaffoldRightBuilder = Widget Function(
  ChatAdaptiveScaffoldBuilderController controller, {
  required bool isInStack,
  required RightColumnType type,
});

class ChatAdaptiveScaffoldBuilder extends StatefulWidget {
  final ChatAdaptiveScaffoldBodyBuilder bodyBuilder;

  final ChatAdaptiveScaffoldRightBuilder rightBuilder;

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
  final rightColumnTypeNotifier = ValueNotifier<RightColumnType?>(null);

  final responsiveUtils = ResponsiveUtils();

  void hideRightColumn() {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).pop();
    } else {
      rightColumnTypeNotifier.value = null;
    }
  }

  void setRightColumnType(RightColumnType type) {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => widget.rightBuilder(
            this,
            isInStack: true,
            type: type,
          ),
        ),
      );
    } else {
      rightColumnTypeNotifier.value = type;
    }
  }

  @override
  void dispose() {
    rightColumnTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = responsiveUtils.getMinDesktopWidth(context);
    return ValueListenableBuilder(
      valueListenable: rightColumnTypeNotifier,
      builder: (context, rightColumnType, body) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: AdaptiveLayout(
            body: SlotLayout(
              config: {
                WidthPlatformBreakpoint(
                  end: breakpoint,
                ): SlotLayout.from(
                  key: AppAdaptiveScaffold.breakpointMobileKey,
                  builder: (_) => Stack(
                    children: [
                      body!,
                      if (rightColumnType != null && PlatformInfos.isWeb)
                        widget.rightBuilder(
                          this,
                          isInStack: true,
                          type: rightColumnType,
                        ),
                    ],
                  ),
                ),
                WidthPlatformBreakpoint(
                  begin: breakpoint,
                ): SlotLayout.from(
                  key: AppAdaptiveScaffold.breakpointWebAndDesktopKey,
                  builder: (_) => Padding(
                    padding: rightColumnType != null
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
            bodyRatio: ResponsiveUtils.bodyWithRightColumnRatio,
            internalAnimations: false,
            secondaryBody: rightColumnType != null
                ? SlotLayout(
                    config: {
                      WidthPlatformBreakpoint(
                        end: breakpoint,
                      ): SlotLayout.from(
                        key: AppAdaptiveScaffold.breakpointMobileKey,
                        builder: null,
                      ),
                      WidthPlatformBreakpoint(
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
