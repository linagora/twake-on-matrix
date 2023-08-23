import 'package:animations/animations.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/input_bar.dart';
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
import 'package:matrix/matrix.dart';

class DraftChatView extends StatelessWidget {
  const DraftChatView(this.controller, {super.key});

  final DraftChatController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.showEmojiPicker &&
        controller.emojiPickerType == EmojiPickerType.reaction) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: DraftChatViewStyle.toolbarHeight(context),
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
                receiverId: controller.presentationContact!.matrixId!,
                displayName: controller.presentationContact!.displayName,
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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: DirectDraftChatView(
                  onTap: () => controller.inputFocus.requestFocus(),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TwakeIconButton(
                        tooltip: L10n.of(context)!.more,
                        margin: const EdgeInsets.only(right: 4.0),
                        icon: Icons.add_circle_outline,
                        onPressed: () => controller.showMediaPicker(context),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding:
                              const EdgeInsetsDirectional.only(start: 12.0),
                          margin: const EdgeInsetsDirectional.only(end: 8.0),
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(25)),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InputBar(
                                  minLines: 1,
                                  maxLines: 8,
                                  autofocus: !PlatformInfos.isMobile,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: AppConfig.sendOnEnter
                                      ? TextInputAction.send
                                      : null,
                                  onSubmitted: controller.onInputBarSubmitted,
                                  focusNode: controller.inputFocus,
                                  controller: controller.sendController,
                                  decoration: InputDecoration(
                                    hintText: L10n.of(context)!.chatMessage,
                                    hintMaxLines: 1,
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.merge(
                                          Theme.of(context)
                                              .inputDecorationTheme
                                              .hintStyle,
                                        )
                                        .copyWith(letterSpacing: -0.15),
                                  ),
                                  onChanged: controller.onInputBarChanged,
                                ),
                              ),
                              KeyBoardShortcuts(
                                keysToPress: {
                                  LogicalKeyboardKey.altLeft,
                                  LogicalKeyboardKey.keyE
                                },
                                onKeysPressed: controller.emojiPickerAction,
                                helpLabel: L10n.of(context)!.emojis,
                                child: InkWell(
                                  onTap: controller.emojiPickerAction,
                                  child: PageTransitionSwitcher(
                                    transitionBuilder: (
                                      Widget child,
                                      Animation<double> primaryAnimation,
                                      Animation<double> secondaryAnimation,
                                    ) {
                                      return SharedAxisTransition(
                                        animation: primaryAnimation,
                                        secondaryAnimation: secondaryAnimation,
                                        transitionType:
                                            SharedAxisTransitionType.scaled,
                                        fillColor: Colors.transparent,
                                        child: child,
                                      );
                                    },
                                    child: !controller.showEmojiPicker
                                        ? TwakeIconButton(
                                            paddingAll:
                                                controller.inputText.isEmpty
                                                    ? 5.0
                                                    : 12,
                                            tooltip: L10n.of(context)!.emojis,
                                            onPressed: () =>
                                                controller.emojiPickerAction(),
                                            icon: Icons.tag_faces,
                                          )
                                        : TwakeIconButton(
                                            paddingAll:
                                                controller.inputText.isEmpty
                                                    ? 5.0
                                                    : 12,
                                            tooltip: L10n.of(context)!.keyboard,
                                            onPressed: () => controller
                                                .inputFocus
                                                .requestFocus(),
                                            icon: Icons.keyboard,
                                          ),
                                  ),
                                ),
                              ),
                              if (PlatformInfos.platformCanRecord &&
                                  controller.inputText.isEmpty)
                                Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  child: TwakeIconButton(
                                    margin: const EdgeInsets.only(right: 7.0),
                                    paddingAll: 5.0,
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
                          controller.inputText.isNotEmpty)
                        Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: TwakeIconButton(
                            size: ChatInputRowStyle.sendIconButtonSize,
                            onPressed: controller.sendText,
                            tooltip: L10n.of(context)!.send,
                            imagePath: ImagePaths.icSend,
                          ),
                        )
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: FluffyThemes.columnWidth * 2.5,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: FluffyThemes.animationDuration,
                    curve: FluffyThemes.animationCurve,
                    width: MediaQuery.of(context).size.width,
                    height: controller.showEmojiPicker
                        ? MediaQuery.of(context).size.height / 3
                        : 0,
                    child: controller.showEmojiPicker
                        ? EmojiPicker(
                            onEmojiSelected:
                                controller.onEmojiBottomSheetSelected,
                            onBackspacePressed: controller.emojiPickerBackspace,
                            config: Config(
                              backspaceColor:
                                  Theme.of(context).colorScheme.primary,
                              bgColor: Theme.of(context).colorScheme.surface,
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
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        child: FutureBuilder<Profile>(
          future: Matrix.of(context).client.getProfileFromUserId(receiverId),
          builder: (context, snapshot) {
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 3, top: 3),
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
                const SizedBox(width: 12),
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
