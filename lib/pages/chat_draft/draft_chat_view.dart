import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat/chat_emoji_picker.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_input_row.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
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
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSendingNotifier,
      builder: (context, isIgnorePointer, child) {
        return IgnorePointer(
          ignoring: isIgnorePointer,
          child: child,
        );
      },
      child: KeyboardDismissOnTap(
        child: Scaffold(
          backgroundColor: DraftChatViewStyle.responsive.isMobile(context)
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().onPrimary,
          appBar: AppBar(
            backgroundColor: DraftChatViewStyle.responsive.isMobile(context)
                ? LinagoraSysColors.material().surface
                : LinagoraSysColors.material().onPrimary,
            automaticallyImplyLeading: false,
            toolbarHeight: ChatViewStyle.appBarHeight(context),
            title: Padding(
              padding: ChatViewStyle.paddingLeading(context),
              child: Row(
                children: [
                  DraftChatViewStyle.responsive.isMobile(context)
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: TwakeIconButton(
                            tooltip: L10n.of(context)!.back,
                            icon: Icons.chevron_left_outlined,
                            onTap: () => context.pop(),
                            paddingAll: 8.0,
                            margin: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        )
                      : const SizedBox.shrink(),
                  Expanded(
                    child: _EmptyChatTitle(
                      receiverId: controller.presentationContact!.matrixId!,
                      displayName: controller.presentationContact!.displayName,
                      onTap: controller.onPushDetails,
                    ),
                  ),
                ],
              ),
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
          body: Container(
            color: DraftChatViewStyle.responsive.isMobile(context)
                ? LinagoraSysColors.material().surface
                : Colors.transparent,
            child: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color:
                            ChatViewBodyStyle.chatViewBackgroundColor(context),
                        child: Center(
                          child: DropTarget(
                            onDragDone: (details) =>
                                controller.handleDragDone(details),
                            onDragEntered: controller.onDragEntered,
                            onDragExited: controller.onDragExited,
                            child: DraftChatEmpty(
                              onTap: () =>
                                  controller.handleDraftAction(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: DraftChatViewStyle.responsive
                              .isMobile(context)
                          ? BoxDecoration(
                              color: LinagoraSysColors.material().surface,
                              border: Border(
                                top: BorderSide(
                                  color: LinagoraStateLayer(
                                    LinagoraSysColors.material().surfaceTint,
                                  ).opacityLayer3,
                                ),
                              ),
                            )
                          : null,
                      child: Column(
                        children: [
                          const SizedBox(height: 8.0),
                          DraftChatInputRow(
                            onEmojiAction: controller.onEmojiAction,
                            onInputBarChanged: controller.onInputBarChanged,
                            onInputBarSubmitted: controller.onInputBarSubmitted,
                            onKeyboardAction: controller.onKeyboardAction,
                            onSendFileClick: controller.onSendFileClick,
                            textEditingController: controller.sendController,
                            typeAheadFocusNode: controller.inputFocus,
                            typeAheadKey:
                                controller.draftChatComposerTypeAheadKey,
                            focusSuggestionController:
                                controller.focusSuggestionController,
                            inputText: controller.inputText,
                            isSendingNotifier: controller.isSendingNotifier,
                            emojiPickerNotifier:
                                controller.showEmojiPickerNotifier,
                          ),
                          SizedBox(
                            height: DraftChatViewStyle.bottomBarInputPadding(
                              context,
                            ),
                          ),
                          ChatEmojiPicker(
                            showEmojiPickerNotifier:
                                controller.showEmojiPickerNotifier,
                            onEmojiSelected:
                                controller.onEmojiBottomSheetSelected,
                            emojiPickerBackspace:
                                controller.emojiPickerBackspace,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    return InkWell(
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
                    name:
                        snapshot.data?.displayName ?? displayName ?? receiverId,
                    size: ChatAppBarTitleStyle.avatarSize(context),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (snapshot.data?.displayName ?? displayName ?? receiverId)
                          .capitalize(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
