import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_actions.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';

/// The "+" button of the composer on mobile: its menu holds Gallery, Documents,
/// Camera and, when the homeserver has a Twake SSO, Add from Drive.
class AttachmentMenuButton extends ConsumerWidget {
  const AttachmentMenuButton({
    super.key,
    required this.onSelected,
    this.iconColor,
  });

  final ValueChanged<AttachmentMenuAction> onSelected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveEnabled = ref.watch(driveConfigProvider).isEnabled;
    return PopupMenuButton<AttachmentMenuAction>(
      tooltip: L10n.of(context)!.more,
      iconSize: ChatInputRowStyle.chatInputRowMoreBtnSize,
      icon: Icon(Icons.add_circle_outline, color: iconColor),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final action in AttachmentMenuAction.available(
          driveEnabled: driveEnabled,
        ))
          PopupMenuItem<AttachmentMenuAction>(
            value: action,
            child: Row(
              children: [
                action.buildIcon(),
                const SizedBox(width: 12),
                Text(action.getTitle(context)),
              ],
            ),
          ),
      ],
    );
  }
}
