import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animations/animations.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../config/themes.dart';
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
    return Row(
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
                                Image.asset('assets/ic_send.png'),
                              ],
                            ),
                          ),
                        )
                  : Container(),
            ]
          : <Widget>[
              KeyBoardShortcuts(
                keysToPress: {
                  LogicalKeyboardKey.altLeft,
                  LogicalKeyboardKey.keyA
                },
                onKeysPressed: () =>
                    controller.onAddPopupMenuButtonSelected('file'),
                helpLabel: L10n.of(context)!.sendFile,
                child: AnimatedContainer(
                  duration: FluffyThemes.animationDuration,
                  curve: FluffyThemes.animationCurve,
                  height: 56,
                  width: 56,
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: PopupMenuButton<String>(
                    icon: Image.asset(
                      'assets/ic_add.png',
                      width: 28,
                      height: 28,
                    ),
                    onSelected: controller.onAddPopupMenuButtonSelected,
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'file',
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.attachment_outlined),
                          ),
                          title: Text(L10n.of(context)!.sendFile),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'image',
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.image_outlined),
                          ),
                          title: Text(L10n.of(context)!.sendImage),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                      if (PlatformInfos.isMobile)
                        PopupMenuItem<String>(
                          value: 'camera',
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.camera_alt_outlined),
                            ),
                            title: Text(L10n.of(context)!.openCamera),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                      if (PlatformInfos.isMobile)
                        PopupMenuItem<String>(
                          value: 'camera-video',
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.videocam_outlined),
                            ),
                            title: Text(L10n.of(context)!.openVideoCamera),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                      if (controller.room!
                          .getImagePacks(ImagePackUsage.sticker)
                          .isNotEmpty)
                        PopupMenuItem<String>(
                          value: 'sticker',
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.emoji_emotions_outlined),
                            ),
                            title: Text(L10n.of(context)!.sendSticker),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                      if (PlatformInfos.isMobile)
                        PopupMenuItem<String>(
                          value: 'location',
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.gps_fixed_outlined),
                            ),
                            title: Text(L10n.of(context)!.shareLocation),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                    ],
                  ),
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
                  constraints: const BoxConstraints(maxHeight: 50),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(left: 12.0, right: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFFE1E3E6),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(25)),
                    color: const Color(0xFFF2F3F5),
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
                            hintText: L10n.of(context)!.writeAMessage,
                            hintMaxLines: 1,
                            hintStyle:
                                const TextStyle(fontSize: 15, height: 1.1),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            filled: false,
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
                            child: Image.asset(
                              controller.showEmojiPicker
                                  ? 'assets/ic_keyboard.png'
                                  : 'assets/ic_emoji.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (PlatformInfos.platformCanRecord &&
                  controller.inputText.isEmpty)
                InkWell(
                  onTap: controller.voiceMessageAction,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.mic_none_outlined,
                      color: Color(0xFF007AFF),
                      size: 24,
                    ),
                  ),
                ),
              if (!PlatformInfos.isMobile || controller.inputText.isNotEmpty)
                Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: IconButton(
                    iconSize: 34,
                    onPressed: controller.send,
                    tooltip: L10n.of(context)!.send,
                    icon: Image.asset('assets/ic_send.png'),
                  ),
                ),
            ],
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
              .map((client) => PopupMenuItem<String>(
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
                        title:
                            Text(snapshot.data?.displayName ?? client.userID!),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                  ))
              .toList(),
          child: Avatar(
            mxContent: snapshot.data?.avatarUrl,
            name: snapshot.data?.displayName ??
                controller.matrix!.client.userID!.localpart,
            size: 20,
          ),
        ),
      ),
    );
  }
}
