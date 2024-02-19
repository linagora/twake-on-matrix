import 'package:fluffychat/pages/chat/chat_input_row_mobile.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_web.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraftChatInputRow extends StatelessWidget {
  final DraftChatController controller;

  const DraftChatInputRow(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ChatViewBodyStyle.inputBarPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (ChatInputRowStyle.responsiveUtils.isMobileOrTablet(context))
            SizedBox(
              height: ChatInputRowStyle.chatInputRowHeight,
              child: TwakeIconButton(
                size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                tooltip: L10n.of(context)!.more,
                icon: Icons.add_circle_outline,
                onTap: () => controller.onSendFileClick(context),
              ),
            ),
          Expanded(
            child: ChatInputRowStyle.responsiveUtils.isMobileOrTablet(context)
                ? _buildMobileInputRow(context)
                : _buildWebInputRow(context),
          ),
          ChatInputRowSendBtn(
            inputText: controller.inputText,
            onTap: controller.onInputBarSubmitted,
          ),
        ],
      ),
    );
  }

  ChatInputRowMobile _buildMobileInputRow(BuildContext context) {
    return ChatInputRowMobile(
      inputBar: _buildInputBar(context),
      emojiPickerNotifier: controller.showEmojiPickerNotifier,
      onEmojiAction: controller.onEmojiAction,
      onKeyboardAction: controller.onKeyboardAction,
    );
  }

  ChatInputRowWeb _buildWebInputRow(BuildContext context) {
    return ChatInputRowWeb(
      inputBar: _buildInputBar(context),
      emojiPickerNotifier: controller.showEmojiPickerNotifier,
      onTapMoreBtn: () => controller.onSendFileClick(context),
      onEmojiAction: controller.onEmojiAction,
      onKeyboardAction: controller.onKeyboardAction,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return InputBar(
      typeAheadKey: controller.draftChatComposerTypeAheadKey,
      minLines: DraftChatViewStyle.minLinesInputBar,
      maxLines: DraftChatViewStyle.maxLinesInputBar,
      autofocus: !PlatformInfos.isMobile,
      keyboardType: TextInputType.multiline,
      textInputAction: null,
      onSubmitted: (_) => controller.onInputBarSubmitted(),
      typeAheadFocusNode: controller.inputFocus,
      controller: controller.sendController,
      decoration: DraftChatViewStyle.bottomBarInputDecoration(
        context,
      ),
      onChanged: controller.onInputBarChanged,
      focusSuggestionController: controller.focusSuggestionController,
    );
  }
}
