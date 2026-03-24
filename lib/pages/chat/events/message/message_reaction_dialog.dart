import 'dart:ui';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat/events/message/message_context_menu_action.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:pull_down_button/pull_down_button.dart';

class MessageReactionDialog extends StatelessWidget {
  final Event event;
  final Timeline timeline;
  final ValueNotifier<bool> displayEmojiPicker;
  final Widget messageWidget;
  final Widget Function({
    required EmojiData emojiData,
    required Event? myReaction,
    required Event event,
    required dynamic relatesTo,
  })
  emojiPickerBuilder;
  final List<MessageContextMenuAction> Function(Event) messageContextMenu;
  final PullDownMenuItemTheme Function(MessageContextMenuAction)
  themeContextMenu;
  final Widget? Function(Event, MessageContextMenuAction) iconContextMenu;
  final OnSendEmojiReactionAction? onSendEmojiReaction;
  final Key dialogSafeAreaKey;

  const MessageReactionDialog({
    super.key,
    required this.event,
    required this.timeline,
    required this.displayEmojiPicker,
    required this.messageWidget,
    required this.emojiPickerBuilder,
    required this.messageContextMenu,
    required this.themeContextMenu,
    required this.iconContextMenu,
    required this.dialogSafeAreaKey,
    this.onSendEmojiReaction,
  });

  @override
  Widget build(BuildContext context) {
    final myReaction = event
        .aggregatedEvents(timeline, RelationshipTypes.reaction)
        .where(
          (event) =>
              event.senderId == event.room.client.userID &&
              event.type == 'm.reaction',
        )
        .firstOrNull;
    final relatesTo =
        (myReaction?.content as Map<String, dynamic>?)?['m.relates_to'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: const Color(0xFF636363).withOpacity(0.2)),
            ),
          ),
          SafeArea(
            key: dialogSafeAreaKey,
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ValueListenableBuilder(
                  valueListenable: displayEmojiPicker,
                  builder: (context, display, child) {
                    return ReactionsDialogWidget(
                      messageWidget: messageWidget,
                      reactionWidget: !event.room.canSendReactions
                          ? const SizedBox.shrink()
                          : display
                          ? emojiPickerBuilder(
                              emojiData: Matrix.of(context).emojiData,
                              myReaction: myReaction,
                              event: event,
                              relatesTo: relatesTo,
                            )
                          : null,
                      isOwnMessage: event.isOwnMessage,
                      emojis: AppConfig.emojisDefault,
                      enableMoreEmojiWidget: true,
                      onPickEmojiReactionAction: () {
                        displayEmojiPicker.value = true;
                      },
                      myEmojiReacted: relatesTo?['key'] ?? '',
                      onClickEmojiReactionAction: (emoji) async {
                        final isSelected = emoji == (relatesTo?['key'] ?? '');
                        if (myReaction == null) {
                          onSendEmojiReaction?.call(emoji, event);
                          return;
                        }

                        if (isSelected) {
                          await myReaction.redactEvent();
                          return;
                        }

                        if (!isSelected) {
                          await myReaction.redactEvent();
                          onSendEmojiReaction?.call(emoji, event);
                          return;
                        }
                      },
                      contextMenuWidget: display
                          ? const SizedBox()
                          : Padding(
                              padding: const .only(top: 16),
                              child: PullDownMenu(
                                routeTheme: PullDownMenuRouteTheme(
                                  backgroundColor:
                                      LinagoraRefColors.material().primary[100],
                                  borderRadius: .circular(20),
                                ),
                                items: messageContextMenu(event)
                                    .map(
                                      (item) => PullDownMenuItem(
                                        title: item.getTitle(context, event),
                                        itemTheme: themeContextMenu(item),
                                        icon: item.getIcon(event),
                                        onTap: () => item.onTap(context),
                                        iconWidget: iconContextMenu(
                                          event,
                                          item,
                                        ),
                                        iconColor: item.getIconColor(
                                          context,
                                          event,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                      widgetAlignment: event.isOwnMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
