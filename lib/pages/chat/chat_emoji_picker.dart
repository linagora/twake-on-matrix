import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/themes.dart';

class ChatEmojiPicker extends StatelessWidget {
  final ValueNotifier<bool> showEmojiPickerNotifier;
  final void Function(Emoji? emoji) onEmojiSelected;
  final void Function() emojiPickerBackspace;

  const ChatEmojiPicker({
    Key? key,
    required this.showEmojiPickerNotifier,
    required this.onEmojiSelected,
    required this.emojiPickerBackspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: showEmojiPickerNotifier,
      builder: (context, showEmojiPicker, child) {
        if (!showEmojiPicker) return child!;

        return AnimatedContainer(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
          ),
          duration: TwakeThemes.animationDuration,
          curve: TwakeThemes.animationCurve,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height / 3,
          child: EmojiPicker(
            onEmojiSelected: (_, emoji) => onEmojiSelected(emoji),
            onBackspacePressed: emojiPickerBackspace,
            config: Config(
              backspaceColor: Theme.of(context).colorScheme.primary,
              bgColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(context).colorScheme.primary,
              iconColorSelected: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
