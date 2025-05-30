import 'package:fluffychat/pages/chat/chat_input_row_mobile.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_web.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_input_row_style.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class DraftChatInputRow extends StatelessWidget {
  final OnSendFileClick onSendFileClick;
  final ValueNotifier<String> inputText;
  final OnInputBarSubmitted onInputBarSubmitted;
  final ValueNotifier<bool> isSendingNotifier;
  final OnEmojiAction onEmojiAction;
  final ValueKey typeAheadKey;
  final OnInputBarChanged onInputBarChanged;
  final FocusNode? typeAheadFocusNode;
  final TextEditingController? textEditingController;
  final FocusSuggestionController focusSuggestionController;

  const DraftChatInputRow({
    super.key,
    required this.onSendFileClick,
    required this.inputText,
    required this.onInputBarSubmitted,
    required this.isSendingNotifier,
    required this.onEmojiAction,
    required this.typeAheadKey,
    required this.onInputBarChanged,
    this.typeAheadFocusNode,
    this.textEditingController,
    required this.focusSuggestionController,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Padding(
          padding: DraftChatInputRowStyle.inputBarPadding(
            context: context,
            isKeyboardVisible: isKeyboardVisible,
          ),
          child: Row(
            crossAxisAlignment:
                ChatInputRowStyle.responsiveUtils.isMobile(context)
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (ChatInputRowStyle.responsiveUtils.isMobile(context))
                SizedBox(
                  height: ChatInputRowStyle.chatInputRowHeight,
                  child: TwakeIconButton(
                    size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                    tooltip: L10n.of(context)!.more,
                    icon: Icons.add_circle_outline,
                    onTap: () => onSendFileClick(context),
                  ),
                ),
              Expanded(
                child: ChatInputRowStyle.responsiveUtils.isMobile(context)
                    ? _buildMobileInputRow(context)
                    : _buildWebInputRow(context),
              ),
              ChatInputRowSendBtn(
                inputText: inputText,
                onTap: onInputBarSubmitted,
                sendingNotifier: isSendingNotifier,
              ),
            ],
          ),
        );
      },
    );
  }

  ChatInputRowMobile _buildMobileInputRow(BuildContext context) {
    return ChatInputRowMobile(
      inputBar: _buildInputBar(context),
    );
  }

  ChatInputRowWeb _buildWebInputRow(BuildContext context) {
    return ChatInputRowWeb(
      inputBar: _buildInputBar(context),
      onTapMoreBtn: () => onSendFileClick(context),
      onEmojiAction: onEmojiAction,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Column(
      children: [
        InputBar(
          typeAheadKey: typeAheadKey,
          minLines: DraftChatViewStyle.minLinesInputBar,
          maxLines: DraftChatViewStyle.maxLinesInputBar,
          autofocus: !PlatformInfos.isMobile,
          keyboardType: TextInputType.multiline,
          textInputAction: null,
          onSubmitted: (_) => onInputBarSubmitted(),
          typeAheadFocusNode: typeAheadFocusNode,
          controller: textEditingController,
          decoration: DraftChatViewStyle.bottomBarInputDecoration(
            context,
          ),
          onChanged: onInputBarChanged,
          focusSuggestionController: focusSuggestionController,
          isDraftChat: true,
        ),
      ],
    );
  }
}
