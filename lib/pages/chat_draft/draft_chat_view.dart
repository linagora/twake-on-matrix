import 'package:animations/animations.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class DraftChatView extends StatelessWidget {
  const DraftChatView({
    super.key,
    required this.controller,
  });

  final DraftChatController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.showEmojiPicker == true &&
        controller.emojiPickerType == EmojiPickerType.reaction) {
      return Container();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSendingNotifier,
      builder: (context, isIgnorePointer, child) {
        return IgnorePointer(
          ignoring: isIgnorePointer,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        appBar: AppBar(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              TwakeIconButton(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                tooltip: L10n.of(context)!.back,
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
                paddingAll: 8.0,
                margin: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              Expanded(
                child: _EmptyChatTitle(
                  receiverId: controller.presentationContact!.matrixId!,
                  displayName: controller.presentationContact!.displayName,
                  onTap: controller.onPushDetails,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 1),
            child: Container(
              color: LinagoraStateLayer(
                LinagoraSysColors.material().surfaceTint,
              ).opacityLayer1,
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
                      child: DropTarget(
                        onDragDone: (details) =>
                            controller.handleDragDone(details),
                        onDragEntered: controller.onDragEntered,
                        onDragExited: controller.onDragExited,
                        child: DirectDraftChatView(
                          onTap: controller.inputFocus.requestFocus,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: DraftChatViewStyle.inputWidgetPadding,
                        child: Container(
                          alignment: Alignment.center,
                          constraints: BoxConstraints(
                            maxWidth: DraftChatViewStyle.maxInputBarWidth,
                          ),
                          padding: const EdgeInsets.only(
                            left: 16.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: DraftChatViewStyle.bottomBarPadding,
                                  decoration: BoxDecoration(
                                    borderRadius: ChatInputRowStyle
                                        .chatInputRowBorderRadius,
                                    color:
                                        LinagoraSysColors.material().onPrimary,
                                    border: Border.all(
                                      color:
                                          LinagoraRefColors.material().tertiary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 12,
                                        child: TwakeIconButton(
                                          tooltip: L10n.of(context)!.more,
                                          margin: DraftChatViewStyle
                                              .buttonAddMoreMargin,
                                          icon: Icons.add_circle_outline,
                                          onTap: () => controller
                                              .onSendFileClick(context),
                                          paddingAll: 0,
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const SizedBox(width: 32.0),
                                          Expanded(
                                            child: Padding(
                                              padding: DraftChatViewStyle
                                                  .inputBarPadding,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: InputBar(
                                                      minLines:
                                                          DraftChatViewStyle
                                                              .minLinesInputBar,
                                                      maxLines:
                                                          DraftChatViewStyle
                                                              .maxLinesInputBar,
                                                      autofocus: !PlatformInfos
                                                          .isMobile,
                                                      keyboardType:
                                                          TextInputType
                                                              .multiline,
                                                      textInputAction: null,
                                                      onSubmitted: controller
                                                          .onInputBarSubmitted,
                                                      focusNode:
                                                          controller.inputFocus,
                                                      controller: controller
                                                          .sendController,
                                                      decoration: DraftChatViewStyle
                                                          .bottomBarInputDecoration(
                                                        context,
                                                      ),
                                                      onChanged: controller
                                                          .onInputBarChanged,
                                                      focusSuggestionController:
                                                          controller
                                                              .focusSuggestionController,
                                                    ),
                                                  ),
                                                  KeyBoardShortcuts(
                                                    keysToPress: {
                                                      LogicalKeyboardKey
                                                          .altLeft,
                                                      LogicalKeyboardKey.keyE,
                                                    },
                                                    onKeysPressed: controller
                                                        .emojiPickerAction,
                                                    helpLabel: L10n.of(context)!
                                                        .emojis,
                                                    child: InkWell(
                                                      onTap: controller
                                                          .emojiPickerAction,
                                                      child:
                                                          PageTransitionSwitcher(
                                                        transitionBuilder: (
                                                          Widget child,
                                                          Animation<double>
                                                              primaryAnimation,
                                                          Animation<double>
                                                              secondaryAnimation,
                                                        ) {
                                                          return SharedAxisTransition(
                                                            animation:
                                                                primaryAnimation,
                                                            secondaryAnimation:
                                                                secondaryAnimation,
                                                            transitionType:
                                                                SharedAxisTransitionType
                                                                    .scaled,
                                                            fillColor: Colors
                                                                .transparent,
                                                            child: child,
                                                          );
                                                        },
                                                        child: null,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (PlatformInfos.platformCanRecord &&
                                              controller.inputText.isEmpty)
                                            Container(
                                              alignment: Alignment.center,
                                              child: TwakeIconButton(
                                                margin: DraftChatViewStyle
                                                    .bottomBarButtonRecordMargin,
                                                paddingAll: DraftChatViewStyle
                                                    .bottomBarButtonRecordPaddingAll,
                                                onTap: controller
                                                    .emojiPickerAction,
                                                tooltip: L10n.of(context)!.send,
                                                icon: Icons.tag_faces,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!PlatformInfos.isMobile ||
                                  controller.inputText.isNotEmpty)
                                Container(
                                  alignment: Alignment.center,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        controller.isSendingNotifier,
                                    builder: (context, isSending, child) {
                                      if (isSending) {
                                        return Padding(
                                          padding: DraftChatViewStyle
                                              .iconLoadingPadding,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator
                                                  .adaptive(),
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding:
                                            DraftChatViewStyle.iconSendPadding,
                                        child: TwakeIconButton(
                                          hoverColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          size:
                                              ChatInputRowStyle.sendIconBtnSize,
                                          onTap: controller.sendText,
                                          tooltip: L10n.of(context)!.send,
                                          imagePath: ImagePaths.icSend,
                                          paddingAll: 0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        constraints:
                            DraftChatViewStyle.containerMaxWidthConstraints,
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: TwakeThemes.animationDuration,
                          curve: TwakeThemes.animationCurve,
                          width: MediaQuery.of(context).size.width,
                          height: DraftChatViewStyle.animatedContainerHeight(
                            context,
                            controller.showEmojiPicker == true,
                          ),
                          child: controller.showEmojiPicker == true
                              ? EmojiPicker(
                                  onEmojiSelected:
                                      controller.onEmojiBottomSheetSelected,
                                  onBackspacePressed:
                                      controller.emojiPickerBackspace,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatTitle extends StatelessWidget {
  const _EmptyChatTitle({
    required this.receiverId,
    this.displayName,
    this.onTap,
  });

  final String receiverId;

  final String? displayName;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DraftChatViewStyle.emptyChatParentPadding,
      child: InkWell(
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: FutureBuilder<Profile>(
          future: _getReceiverProfile(context, receiverId),
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
                      size: ChatAppBarTitleStyle.avatarSize,
                    ),
                  ),
                ),
                SizedBox(width: DraftChatViewStyle.emptyChatGapWidth),
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

  Future<Profile> _getReceiverProfile(
    BuildContext context,
    String receiverId,
  ) async {
    try {
      return await Matrix.of(context)
          .client
          .getProfileFromUserId(receiverId, getFromRooms: false);
    } catch (e) {
      return Profile(
        avatarUrl: null,
        displayName: null,
        userId: receiverId,
      );
    }
  }
}
