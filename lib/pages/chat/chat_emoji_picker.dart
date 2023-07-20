import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/themes.dart';
import 'chat.dart';

class ChatEmojiPicker extends StatelessWidget {
  final ChatController controller;
  const ChatEmojiPicker(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      width: MediaQuery.of(context).size.width,
      height: controller.showEmojiPicker
          ? MediaQuery.of(context).size.height / 3
          : 0,
      child: controller.showEmojiPicker
          ? EmojiPicker(
              onEmojiSelected: controller.onEmojiSelected,
              onBackspacePressed: controller.emojiPickerBackspace,
              config: Config(
                backspaceColor: Theme.of(context).colorScheme.primary,
                bgColor: Theme.of(context).colorScheme.surface,
                indicatorColor: Theme.of(context).colorScheme.primary,
                iconColorSelected: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }
}
