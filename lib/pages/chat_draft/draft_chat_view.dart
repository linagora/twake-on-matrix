import 'package:animations/animations.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/input_bar.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/presentation/model/chat_draft/chat_draft_argument.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/string_extension.dart';

class DraftChatView extends StatelessWidget {
  const DraftChatView({
    super.key,
    required this.chatDraftArgument,
  });

  final ChatDraftArgument chatDraftArgument;

  @override
  Widget build(BuildContext context) {
    if (chatDraftArgument.showEmojiPicker == true &&
        chatDraftArgument.emojiPickerType == EmojiPickerType.reaction) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: DraftChatViewStyle.toolbarHeight,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            TwakeIconButton(
              tooltip: L10n.of(context)!.back,
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
              paddingAll: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            Expanded(
              child: _EmptyChatTitle(
                receiverId: chatDraftArgument.matrixId!,
                displayName: chatDraftArgument.displayName,
              ),
            )
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 4),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: DraftChatViewStyle.containerMaxWidthConstraints,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: DirectDraftChatView(
                      onTap: chatDraftArgument.onTapDirectDraftChat,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: DraftChatViewStyle.inputWidgetPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TwakeIconButton(
                            tooltip: L10n.of(context)!.more,
                            margin: DraftChatViewStyle.buttonAddMoreMargin,
                            icon: Icons.add_circle_outline,
                            onPressed: chatDraftArgument.onPressedAddMore,
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              padding: DraftChatViewStyle.bottomBarPadding,
                              margin: DraftChatViewStyle.bottomBarMargin,
                              decoration: BoxDecoration(
                                borderRadius:
                                    DraftChatViewStyle.bottomBarBorderRadius,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InputBar(
                                      minLines:
                                          DraftChatViewStyle.minLinesInputBar,
                                      maxLines:
                                          DraftChatViewStyle.maxLinesInputBar,
                                      autofocus: !PlatformInfos.isMobile,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: AppConfig.sendOnEnter
                                          ? TextInputAction.send
                                          : null,
                                      onSubmitted:
                                          chatDraftArgument.onInputBarSubmitted,
                                      focusNode: chatDraftArgument.inputFocus,
                                      controller: chatDraftArgument
                                          .textEditingController,
                                      decoration: DraftChatViewStyle
                                          .bottomBarInputDecoration(context),
                                      onChanged:
                                          chatDraftArgument.onInputBarChanged,
                                    ),
                                  ),
                                  KeyBoardShortcuts(
                                    keysToPress: {
                                      LogicalKeyboardKey.altLeft,
                                      LogicalKeyboardKey.keyE
                                    },
                                    onKeysPressed:
                                        chatDraftArgument.emojiPickerAction,
                                    helpLabel: L10n.of(context)!.emojis,
                                    child: InkWell(
                                      onTap:
                                          chatDraftArgument.emojiPickerAction,
                                      child: PageTransitionSwitcher(
                                        transitionBuilder: (
                                          Widget child,
                                          Animation<double> primaryAnimation,
                                          Animation<double> secondaryAnimation,
                                        ) {
                                          return SharedAxisTransition(
                                            animation: primaryAnimation,
                                            secondaryAnimation:
                                                secondaryAnimation,
                                            transitionType:
                                                SharedAxisTransitionType.scaled,
                                            fillColor: Colors.transparent,
                                            child: child,
                                          );
                                        },
                                        child: _keyBoardShortcutsButtonBuilder(
                                          context,
                                          chatDraftArgument.showEmojiPicker ==
                                              false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (PlatformInfos.platformCanRecord &&
                                      chatDraftArgument.inputText.isEmpty)
                                    Container(
                                      height: DraftChatViewStyle
                                          .bottomBarButtonButtonContainerHeight,
                                      alignment: Alignment.center,
                                      child: TwakeIconButton(
                                        margin: DraftChatViewStyle
                                            .bottomBarButtonRecordMargin,
                                        paddingAll: DraftChatViewStyle
                                            .bottomBarButtonRecordPaddingAll,
                                        onPressed: () {},
                                        tooltip: L10n.of(context)!.send,
                                        icon: Icons.mic_none,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!PlatformInfos.isMobile ||
                              chatDraftArgument.inputText.isNotEmpty)
                            Container(
                              height: DraftChatViewStyle
                                  .bottomBarButtonButtonContainerHeight,
                              alignment: Alignment.center,
                              child: TwakeIconButton(
                                size: ChatInputRowStyle.sendIconButtonSize,
                                onPressed: chatDraftArgument.sendText,
                                tooltip: L10n.of(context)!.send,
                                imagePath: ImagePaths.icSend,
                              ),
                            )
                        ],
                      ),
                    ),
                    Container(
                      constraints:
                          DraftChatViewStyle.containerMaxWidthConstraints,
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: FluffyThemes.animationDuration,
                        curve: FluffyThemes.animationCurve,
                        width: MediaQuery.of(context).size.width,
                        height: DraftChatViewStyle.animatedContainerHeight(
                          context,
                          chatDraftArgument.showEmojiPicker == true,
                        ),
                        child: chatDraftArgument.showEmojiPicker == true
                            ? EmojiPicker(
                                onEmojiSelected: chatDraftArgument
                                    .onEmojiBottomSheetSelected,
                                onBackspacePressed:
                                    chatDraftArgument.emojiPickerBackspace,
                                config: Config(
                                  backspaceColor:
                                      Theme.of(context).colorScheme.primary,
                                  bgColor:
                                      Theme.of(context).colorScheme.surface,
                                  indicatorColor:
                                      Theme.of(context).colorScheme.primary,
                                  iconColorSelected:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyBoardShortcutsButtonBuilder(
    BuildContext context,
    bool isEmojiPicker,
  ) {
    return TwakeIconButton(
      paddingAll: DraftChatViewStyle.bottomBarButtonPaddingAll(
        chatDraftArgument.inputText.isEmpty,
      ),
      tooltip:
          isEmojiPicker ? L10n.of(context)!.keyboard : L10n.of(context)!.emojis,
      onPressed: isEmojiPicker
          ? () => chatDraftArgument.inputFocus?.requestFocus()
          : chatDraftArgument.emojiPickerAction,
      icon: isEmojiPicker ? Icons.keyboard : Icons.tag_faces,
    );
  }
}

class _EmptyChatTitle extends StatelessWidget {
  const _EmptyChatTitle({required this.receiverId, this.displayName});

  final String receiverId;

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DraftChatViewStyle.emptyChatParentPadding,
      child: InkWell(
        child: FutureBuilder<Profile>(
          future: Matrix.of(context).client.getProfileFromUserId(receiverId),
          builder: (context, snapshot) {
            return Row(
              children: [
                Padding(
                  padding: DraftChatViewStyle.emptyChatChildrenPadding,
                  child: Hero(
                    tag: 'content_banner',
                    child: Avatar(
                      fontSize: ChatAppBarTitleStyle.avatarFontSize,
                      mxContent: snapshot.data?.avatarUrl,
                      name: snapshot.data?.displayName ??
                          displayName ??
                          receiverId,
                      size: ChatAppBarTitleStyle.avatarSize(context),
                    ),
                  ),
                ),
                const SizedBox(width: DraftChatViewStyle.emptyChatGapWidth),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (snapshot.data?.displayName ??
                                displayName ??
                                receiverId)
                            .capitalize(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing:
                                  ChatAppBarTitleStyle.letterSpacingRoomName,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
