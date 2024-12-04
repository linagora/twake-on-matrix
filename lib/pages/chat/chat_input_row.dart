import 'package:fluffychat/pages/chat/chat_input_row_mobile.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_web.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

import 'chat.dart';
import 'input_bar/input_bar.dart';

class ChatInputRow extends StatelessWidget {
  final ChatController controller;

  const ChatInputRow(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.showEmojiPickerNotifier.value &&
        controller.emojiPickerType == EmojiPickerType.reaction) {
      return Container();
    }
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Padding(
          padding: _paddingInputRow(
            context: context,
            isKeyboardVisible: isKeyboardVisible,
          ),
          child: Row(
            crossAxisAlignment:
                ChatInputRowStyle.responsiveUtils.isMobileOrTablet(context)
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: controller.selectMode
                ? [
                    ActionSelectModeWidget(
                      controller: controller,
                    ),
                  ]
                : <Widget>[
                    if (ChatInputRowStyle.responsiveUtils
                        .isMobileOrTablet(context))
                      SizedBox(
                        height: ChatInputRowStyle.chatInputRowHeight,
                        child: TwakeIconButton(
                          size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                          tooltip: L10n.of(context)!.more,
                          icon: Icons.add_circle_outline,
                          onTap: () => controller.onSendFileClick(context),
                        ),
                      ),
                    if (controller.matrix!.isMultiAccount &&
                        controller.matrix!.hasComplexBundles &&
                        controller.matrix!.currentBundle!.length > 1)
                      Container(
                        height: ChatInputRowStyle.chatInputRowHeight,
                        alignment: Alignment.center,
                        child: ChatAccountPicker(controller),
                      ),
                    Expanded(
                      child: ChatInputRowStyle.responsiveUtils
                              .isMobileOrTablet(context)
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
      },
    );
  }

  EdgeInsetsGeometry _paddingInputRow({
    required BuildContext context,
    required bool isKeyboardVisible,
  }) {
    if (!ChatInputRowStyle.responsiveUtils.isMobileOrTablet(context)) {
      return EdgeInsets.zero;
    }

    if (isKeyboardVisible) {
      return EdgeInsets.zero;
    }
    return const EdgeInsets.only(
      bottom: 16,
    );
  }

  ChatInputRowMobile _buildMobileInputRow(BuildContext context) {
    return ChatInputRowMobile(
      inputBar: Column(
        children: [
          ReplyDisplay(controller),
          _buildInputBar(context),
        ],
      ),
      emojiPickerNotifier: controller.showEmojiPickerNotifier,
      onEmojiAction: controller.onEmojiAction,
      onKeyboardAction: controller.onKeyboardAction,
    );
  }

  ChatInputRowWeb _buildWebInputRow(BuildContext context) {
    return ChatInputRowWeb(
      inputBar: Column(
        children: [
          ReplyDisplay(controller),
          _buildInputBar(context),
        ],
      ),
      emojiPickerNotifier: controller.showEmojiPickerNotifier,
      onTapMoreBtn: () => controller.onSendFileClick(context),
      onEmojiAction: controller.onEmojiAction,
      onKeyboardAction: controller.onKeyboardAction,
    );
  }

  InputBar _buildInputBar(BuildContext context) {
    return InputBar(
      typeAheadKey: controller.chatComposerTypeAheadKey,
      rawKeyboardFocusNode: controller.rawKeyboardListenerFocusNode,
      room: controller.room!,
      minLines: 1,
      maxLines: 8,
      autofocus: !PlatformInfos.isMobile,
      keyboardType: TextInputType.multiline,
      textInputAction: null,
      onSubmitted: (_) => controller.onInputBarSubmitted(),
      suggestionsController: controller.suggestionsController,
      typeAheadFocusNode: controller.inputFocus,
      controller: controller.sendController,
      focusSuggestionController: controller.focusSuggestionController,
      suggestionScrollController: controller.suggestionScrollController,
      showEmojiPickerNotifier: controller.showEmojiPickerNotifier,
      decoration: InputDecoration(
        contentPadding: ChatInputRowStyle.contentPadding(context),
        hintText: L10n.of(context)!.message,
        isDense: true,
        hintMaxLines: 1,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: controller.responsive.isMobile(context)
                  ? LinagoraRefColors.material().tertiary[50]
                  : LinagoraRefColors.material().tertiary[30],
              fontFamily: 'Inter',
            ),
      ),
      onChanged: controller.onInputBarChanged,
    );
  }
}

class ActionSelectModeWidget extends StatelessWidget {
  final ChatController controller;

  const ActionSelectModeWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.selectedEvents.first
              .getDisplayEvent(controller.timeline!)
              .status
              .isSent)
            SizedBox(
              height: ChatInputRowStyle.chatInputRowHeight,
              child: TextButton(
                onPressed: controller.forwardEventsAction,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.keyboard_arrow_left_outlined),
                    Text(L10n.of(context)!.forward),
                  ],
                ),
              ),
            ),
          if (controller.selectedEvents.length == 1) ...[
            if (controller.selectedEvents.first
                .getDisplayEvent(controller.timeline!)
                .status
                .isSent) ...[
              SizedBox(
                height: ChatInputRowStyle.chatInputRowHeight,
                child: TextButton(
                  onPressed: controller.replyAction,
                  child: Row(
                    children: <Widget>[
                      Text(L10n.of(context)!.reply),
                      const Icon(Icons.keyboard_arrow_right),
                    ],
                  ),
                ),
              ),
            ] else if (controller.selectedEvents.first
                .getDisplayEvent(controller.timeline!)
                .status
                .isError) ...[
              SizedBox(
                height: ChatInputRowStyle.chatInputRowHeight,
                child: TextButton(
                  onPressed: controller.sendAgainAction,
                  child: Row(
                    children: <Widget>[
                      Text(L10n.of(context)!.tryToSendAgain),
                      const SizedBox(width: 4),
                      SvgPicture.asset(ImagePaths.icSend),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox.shrink(),
            ],
          ],
        ],
      ),
    );
  }
}

class ChatAccountPicker extends StatelessWidget {
  final ChatController controller;

  const ChatAccountPicker(this.controller, {super.key});

  void _popupMenuButtonSelected(String mxid) {
    final client = controller.matrix!.currentBundle!
        .firstWhere((cl) => cl!.userID == mxid, orElse: () => null);
    if (client == null) {
      Logs().w('Attempted to switch to a non-existing client $mxid');
      return;
    }
    controller.setSendingClient(client);
  }

  @override
  Widget build(BuildContext context) {
    controller.matrix ??= Matrix.of(context);
    final clients = controller.currentRoomBundle;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<Profile>(
        future: controller.sendingClient!.fetchOwnProfile(),
        builder: (context, snapshot) => PopupMenuButton<String>(
          onSelected: _popupMenuButtonSelected,
          itemBuilder: (BuildContext context) => clients
              .map(
                (client) => PopupMenuItem<String>(
                  value: client!.userID,
                  child: FutureBuilder<Profile>(
                    future: client.fetchOwnProfile(),
                    builder: (context, snapshot) => ListTile(
                      leading: Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name: snapshot.data?.displayName ??
                            client.userID!.localpart,
                        size: 20,
                      ),
                      title: Text(snapshot.data?.displayName ?? client.userID!),
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              )
              .toList(),
          child: Avatar(
            mxContent: snapshot.data?.avatarUrl,
            name: snapshot.data?.displayName ??
                controller.matrix!.client.userID!.localpart,
            size: 20,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
