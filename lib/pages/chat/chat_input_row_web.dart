import 'package:animations/animations.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/input_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';

typedef OnTapMoreBtnAction = void Function();
typedef OnTapEmojiAction = void Function();
typedef OnTapKeyboardAction = void Function();

class ChatInputRowWeb extends StatelessWidget {
  const ChatInputRowWeb({
    super.key,
    required this.inputBar,
    required this.showEmojiPicker,
    required this.inputText,
    required this.onTapMoreBtn,
    required this.onEmojiAction,
    required this.onKeyboardAction,
  });

  final InputBar inputBar;
  final bool showEmojiPicker;
  final ValueNotifier<String> inputText;
  final OnTapMoreBtnAction onTapMoreBtn;
  final OnTapEmojiAction onEmojiAction;
  final OnTapKeyboardAction onKeyboardAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: ChatInputRowStyle.chatInputRowMargin,
      decoration: BoxDecoration(
        borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TwakeIconButton(
            tooltip: L10n.of(context)!.more,
            paddingAll: 0.0,
            margin: const EdgeInsets.all(12.0),
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
                child: !showEmojiPicker
                    ? ValueListenableBuilder(
                        valueListenable: inputText,
                        builder: (context, value, child) {
                          return TwakeIconButton(
                            margin: ChatInputRowStyle.chatInputRowBtnMarginWeb,
                            paddingAll: 0.0,
                            size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                            tooltip: L10n.of(context)!.emojis,
                            onTap: onEmojiAction,
                            icon: Icons.tag_faces,
                          );
                        },
                      )
                    : ValueListenableBuilder(
                        valueListenable: inputText,
                        builder: (context, value, child) {
                          return TwakeIconButton(
                            margin: ChatInputRowStyle.chatInputRowBtnMarginWeb,
                            paddingAll: 0,
                            size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                            tooltip: L10n.of(context)!.keyboard,
                            onTap: onKeyboardAction,
                            icon: Icons.keyboard,
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
