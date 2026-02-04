import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_message_action.dart';
import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_mute_action.dart';
import 'package:fluffychat/presentation/model/chat/chat_details/chat_details_search_action.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsGroupActionsView extends StatelessWidget {
  const ChatDetailsGroupActionsView({
    super.key,
    required this.onMessage,
    required this.onSearch,
    required this.onToggleNotification,
    required this.muteNotifier,
    required this.animationController,
  });

  final VoidCallback onMessage;
  final VoidCallback onSearch;
  final VoidCallback onToggleNotification;
  final ValueNotifier<PushRuleState> muteNotifier;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder(
      valueListenable: muteNotifier,
      builder: (context, value, child) {
        final actions = [
          ChatDetailsMessageAction(onMessage: onMessage),
          ChatDetailsMuteAction(
            onMute: onToggleNotification,
            isMute: value != PushRuleState.notify,
          ),
          ChatDetailsSearchAction(onSearch: onSearch),
        ];

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            12,
            8,
            12,
            Tween<double>(
              begin: 0,
              end: 16,
            ).transform(animationController.value),
          ),
          child: Row(
            children: List.generate(actions.length, (index) {
              final padding =
                  EdgeInsetsDirectional.only(start: index == 0 ? 0 : 12);
              return Expanded(
                child: Padding(
                  padding: padding,
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    color: sysColor.onPrimary.withValues(
                      alpha: 1 - animationController.value * 0.8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: actions[index].onTap,
                      onTapDown: (details) =>
                          actions[index].onTapDown?.call(context, details),
                      child: Container(
                        alignment: Alignment.center,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(9, 3, 9, 6),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            Icon(
                              actions[index].icon,
                              size: 24,
                              color: ColorTween(
                                begin: sysColor.primary,
                                end: sysColor.onPrimary,
                              ).transform(animationController.value),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              actions[index].getTitle(context),
                              style: textTheme.labelSmall?.copyWith(
                                color: ColorTween(
                                  begin: sysColor.onSurface,
                                  end: sysColor.onPrimary,
                                ).transform(animationController.value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
