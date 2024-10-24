import 'package:animations/animations.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

typedef OnTapMoreBtnAction = void Function();
typedef OnTapEmojiAction = void Function();
typedef OnTapKeyboardAction = void Function();

class ChatInputRowWeb extends StatelessWidget {
  const ChatInputRowWeb({
    super.key,
    required this.inputBar,
    required this.emojiPickerNotifier,
    required this.onTapMoreBtn,
    required this.onEmojiAction,
    required this.onKeyboardAction,
  });

  final Widget inputBar;
  final ValueNotifier<bool> emojiPickerNotifier;
  final OnTapMoreBtnAction onTapMoreBtn;
  final OnTapEmojiAction onEmojiAction;
  final OnTapKeyboardAction onKeyboardAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
        color: LinagoraSysColors.material().onPrimary,
        border: Border.all(
          color: LinagoraRefColors.material().tertiary,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.more,
            paddingAll: 0.0,
            margin: const EdgeInsets.all(10.0),
            iconColor: LinagoraSysColors.material().tertiary,
            icon: Icons.add_circle_outline,
            size: ChatInputRowStyle.chatInputRowMoreBtnSize,
            onTap: onTapMoreBtn,
          ),
          Expanded(
            child: inputBar,
          ),
          KeyBoardShortcuts(
            keysToPress: {LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyE},
            onKeysPressed: onEmojiAction,
            helpLabel: L10n.of(context)!.emojis,
            child: InkWell(
              onTap: onEmojiAction,
              hoverColor: Colors.transparent,
              child: PageTransitionSwitcher(
                transitionBuilder: (
                  Widget child,
                  Animation<double> primaryAnimation,
                  Animation<double> secondaryAnimation,
                ) {
                  return SharedAxisTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.scaled,
                    fillColor: Colors.transparent,
                    child: child,
                  );
                },
                child: ValueListenableBuilder(
                  valueListenable: emojiPickerNotifier,
                  builder: (context, showEmojiPicker, child) {
                    return TwakeIconButton(
                      iconColor: LinagoraSysColors.material().tertiary,
                      paddingAll: ChatInputRowStyle.chatInputRowPaddingBtnWeb,
                      tooltip: L10n.of(context)!.emojis,
                      onTap: showEmojiPicker ? onKeyboardAction : onEmojiAction,
                      icon: showEmojiPicker ? Icons.keyboard : Icons.tag_faces,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
