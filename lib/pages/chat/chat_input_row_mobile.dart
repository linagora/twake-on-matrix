import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnTapEmojiAction = void Function();

class ChatInputRowMobile extends StatelessWidget {
  const ChatInputRowMobile({
    super.key,
    required this.inputBar,
    this.onLongPress,
  });

  final Widget inputBar;

  final void Function()? onLongPress;

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
          children: [
            Expanded(
              child: inputBar,
            ),
            TwakeIconButton(
              iconColor: LinagoraSysColors.material().tertiary,
              tooltip: L10n.of(context)!.holdToRecordAudio,
              icon: Icons.keyboard_voice_outlined,
              tooltipTriggerMode: TooltipTriggerMode.tap,
              onLongPress: onLongPress,
            ),
          ],
        ),
      ),
    );
  }
}
