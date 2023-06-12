import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animations/animations.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'chat.dart';
import 'input_bar.dart';

class ChatInputRow extends StatelessWidget {
  final ChatController controller;

  const ChatInputRow(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.showEmojiPicker &&
        controller.emojiPickerType == EmojiPickerType.reaction) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: controller.selectMode
            ? <Widget>[
                SizedBox(
                  height: 56,
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
                controller.selectedEvents.length == 1
                    ? controller.selectedEvents.first
                            .getDisplayEvent(controller.timeline!)
                            .status
                            .isSent
                        ? SizedBox(
                            height: 56,
                            child: TextButton(
                              onPressed: controller.replyAction,
                              child: Row(
                                children: <Widget>[
                                  Text(L10n.of(context)!.reply),
                                  const Icon(Icons.keyboard_arrow_right),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 56,
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
                          )
                    : Container(),
              ]
            : <Widget>[
                TwakeIconButton(
                  tooltip: L10n.of(context)!.more,
                  margin: const EdgeInsets.only(right: 4.0),
                  icon: Icons.add_circle_outline,
                  onPressed: () => showImagesPickerBottomSheet(
                    controller: controller,
                    context: context,
                  ),
                ),
                if (controller.matrix!.isMultiAccount &&
                    controller.matrix!.hasComplexBundles &&
                    controller.matrix!.currentBundle!.length > 1)
                  Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: _ChatAccountPicker(controller),
                  ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 12.0),
                    margin: const EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InputBar(
                            room: controller.room!,
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
                              hintStyle: Theme.of(context).textTheme.bodyLarge?.merge(
                                Theme.of(context).inputDecorationTheme.hintStyle
                              ).copyWith(letterSpacing: -0.15)
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
                                  transitionType: SharedAxisTransitionType.scaled,
                                  fillColor: Colors.transparent,
                                  child: child,
                                );
                              },
                              child: TwakeIconButton(
                                paddingAll: controller.inputText.isEmpty ? 5.0: 12,
                                tooltip: "Emojis",
                                onPressed: () {print;},
                                icon: Icons.tag_faces,
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
                              onPressed: controller.voiceMessageAction,
                              tooltip: L10n.of(context)!.send,
                              icon: Icons.mic_none,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!PlatformInfos.isMobile || controller.inputText.isNotEmpty)
                  Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: TwakeIconButton(
                      size: ChatInputRowStyle.sendIconButtonSize,
                      onPressed: controller.send,
                      tooltip: L10n.of(context)!.send,
                      imagePath: ImagePaths.icSend,
                    ),
                  ),
              ],
      ),
    );
  }
}

class _ChatAccountPicker extends StatelessWidget {
  final ChatController controller;

  const _ChatAccountPicker(this.controller, {Key? key}) : super(key: key);

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

void showImagesPickerBottomSheet({
  required BuildContext context,
  required ChatController controller,
}) {
  ImagePicker.showImagesGridBottomSheet(
    context: context,
    controller: controller.imagePickerController,
    backgroundImageCamera: const AssetImage("assets/verification.png"),
    counterImageBuilder: (counterImage) {
      if (counterImage == 0) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0, top: 16.0),
        child: Row(
          children: [
            Text(L10n.of(context)!.photoSelectedCounter(counterImage),
              style: Theme.of(context).textTheme.titleMedium,),
            const Icon(Icons.chevron_right),
            const Expanded(child: SizedBox.shrink()),
            const Icon(Icons.more_vert),
          ],
        ),
      );
    },
    noImagesWidget: const Center(
      child: Text("No images found"),
    ),
    bottomWidget: ValueListenableBuilder(
      valueListenable: controller.numberSelectedImagesNotifier,
      builder: (context, value, child) {
        if (value == 0) {
          return const SizedBox.shrink();
        }
        return child!;
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.only(right: 20.0, top: 8.0, bottom: 8.0, left: 4.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.16),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.tag_faces, color: LinagoraRefColors.material().neutralVariant,),
                          hintText: L10n.of(context)!.addACaption,
                        ),
                      ),
                    ),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        SvgPicture.asset(
                          ImagePaths.icSend,
                          width: 40,
                          height: 40,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Positioned(
                right: 12.0,
                bottom: 2.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: ShapeDecoration(
                    shape: CircleBorder(side: BorderSide(color: Theme.of(context).colorScheme.surface)),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  alignment: Alignment.center,
                  child: ValueListenableBuilder(
                    valueListenable: controller.numberSelectedImagesNotifier,
                    builder: (context, value, child) {
                      return Text("$value", style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        letterSpacing: 0.1,
                      ),);
                    },
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8.0,),
        ],
      ),
    )
  );
                
}