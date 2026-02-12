import 'package:fluffychat/pages/chat/disabled_chat_input_row_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class DisabledChatInputRow extends StatelessWidget {
  const DisabledChatInputRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        DisabledChatInputRowStyle.chatDisabledBottomBarPadding,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      height: DisabledChatInputRowStyle.chatDisabledBottomBarHeight,
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: DisabledChatInputRowStyle.chatDisabledBottomBarIconSize,
              color: LinagoraRefColors.material().tertiary[30],
            ),
            const SizedBox(
              width: DisabledChatInputRowStyle.chatDisabledBottomBarIconSpacing,
            ),
            Flexible(
              child: Text(
                L10n.of(context)!.noChatPermissionMessage,
                maxLines: 2,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LinagoraRefColors.material().tertiary[30],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
