import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart' as emoji_mart;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/settings_folders_style.dart';
import 'package:twake_chat/providers/emoji_data_provider.dart';
import 'package:twake_chat/utils/adaptive_bottom_sheet.dart';

/// The emoji of the folder, from the picker of the chat.
class FolderEmojiButton extends StatelessWidget {
  const FolderEmojiButton({
    super.key,
    required this.emoji,
    required this.onChanged,
  });

  final String? emoji;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    // An empty string is the sheet's Clear.
    final picked = await showAdaptiveBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _EmojiSheet(canClear: emoji != null),
    );
    if (picked == null) return;
    onChanged(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final emoji = this.emoji;
    return IconButton(
      key: const ValueKey('folder_emoji'),
      tooltip: L10n.of(context)!.folderEmoji,
      onPressed: () => _pick(context),
      icon: emoji == null
          ? Icon(
              Icons.add_reaction_outlined,
              color: LinagoraSysColors.material().tertiary,
            )
          : Text(emoji, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _EmojiSheet extends ConsumerWidget {
  const _EmojiSheet({required this.canClear});

  final bool canClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final navigator = Navigator.of(context);
    return SafeArea(
      child: Padding(
        padding: SettingsFoldersStyle.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SettingsFoldersStyle.rowGap,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.folderEmoji,
                    style: LinagoraTextStyle.material().titleMedium,
                  ),
                ),
                if (canClear)
                  LinagoraButton(
                    key: const ValueKey('folder_emoji_clear'),
                    variant: LinagoraButtonVariant.text,
                    size: LinagoraButtonSize.xs,
                    label: l10n.clear,
                    onPressed: () => navigator.pop(''),
                  ),
              ],
            ),
            // Shrinks on a short screen instead of overflowing the sheet.
            Flexible(
              child: SizedBox(
                height: SettingsFoldersStyle.emojiPickerHeight,
                child: emoji_mart.EmojiPicker(
                  emojiData: ref.read(emojiDataProvider).requireValue,
                  configuration: emoji_mart.EmojiPickerConfiguration(
                    emojiStyle: Theme.of(context).textTheme.headlineLarge!,
                  ),
                  onEmojiSelected: (emojiId, emoji) => navigator.pop(emoji),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
