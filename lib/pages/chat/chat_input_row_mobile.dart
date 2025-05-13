import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

typedef OnTapEmojiAction = void Function();
typedef OnTapKeyboardAction = void Function();

class ChatInputRowMobile extends StatelessWidget {
  const ChatInputRowMobile({
    super.key,
    required this.inputBar,
    required this.onKeyboardAction,
  });

  final Widget inputBar;
  final OnTapKeyboardAction onKeyboardAction;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: ChatInputRowStyle.chatInputRowHeight,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: ChatInputRowStyle.chatInputRowPaddingMobile,
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
          children: [
            Expanded(
              child: inputBar,
            ),
          ],
        ),
      ),
    );
  }
}
