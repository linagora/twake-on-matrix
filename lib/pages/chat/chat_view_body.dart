import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_loading_view.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:fluffychat/pages/chat/sticky_timestamp_widget.dart';
import 'package:fluffychat/pages/chat/tombstone_display.dart';
import 'package:fluffychat/presentation/model/chat/view_event_list_ui_state.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/widgets/connection_status_header.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'chat_emoji_picker.dart';
import 'chat_input_row.dart';

class ChatViewBody extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatViewBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) => controller.handleDragDone(details),
      onDragEntered: controller.onDragEntered,
      onDragExited: controller.onDragExited,
      child: Container(
        color: controller.responsive.isMobile(context)
            ? LinagoraSysColors.material().surface
            : null,
        child: Stack(
          children: <Widget>[
            if (Matrix.of(context).wallpaper != null)
              Image.file(
                Matrix.of(context).wallpaper!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (controller.room!.pinnedEventIds.isNotEmpty)
                      const SizedBox(
                        height: ChatViewStyle.pinnedMessageHintHeight,
                      ),
                    Expanded(
                      child: Container(
                        color: ChatViewBodyStyle.chatViewBackgroundColor(
                          context,
                        ),
                        child: GestureDetector(
                          onTap: controller.clearSingleSelectedEvent,
                          child: ValueListenableBuilder(
                            valueListenable:
                                controller.openingChatViewStateNotifier,
                            builder: (context, viewState, __) {
                              if (viewState is ViewEventListLoading ||
                                  controller.timeline == null) {
                                return const ChatLoadingView();
                              }

                              if (viewState is ViewEventListSuccess) {
                                return ChatEventList(
                                  controller: controller,
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                    if (controller.room!.canSendDefaultMessages &&
                        controller.room!.membership == Membership.join)
                      Center(
                        child: Container(
                          alignment: Alignment.center,
                          child: controller.room?.isAbandonedDMRoom == true
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                    left: ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                    right: ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        icon: const Icon(
                                          Icons.archive_outlined,
                                        ),
                                        onPressed: () => controller.leaveChat(
                                          context,
                                          controller.room,
                                        ),
                                        label: Text(
                                          L10n.of(context)!.leave,
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                        ),
                                        icon: const Icon(
                                          Icons.chat_outlined,
                                        ),
                                        onPressed: controller.recreateChat,
                                        label: Text(
                                          L10n.of(context)!.reopenChat,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _inputMessageWidget(context),
                        ),
                      ),
                  ],
                ),
                TombstoneDisplay(controller),
                Column(
                  children: [
                    PinnedEventsView(controller),
                    if (controller.room!.pinnedEventIds.isNotEmpty)
                      Divider(
                        height: ChatViewBodyStyle.dividerSize,
                        thickness: ChatViewBodyStyle.dividerSize,
                        color: Theme.of(context).dividerColor,
                      ),
                    SizedBox(
                      key: controller.stickyTimestampKey,
                      child: ValueListenableBuilder(
                        valueListenable: controller.stickyTimestampNotifier,
                        builder: (context, stickyTimestamp, child) {
                          return StickyTimestampWidget(
                            isStickyHeader: stickyTimestamp != null,
                            content: stickyTimestamp != null
                                ? stickyTimestamp.relativeTime(context)
                                : '',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: controller.draggingNotifier,
              builder: (context, dragging, _) {
                if (!dragging) return const SizedBox.shrink();
                return Container(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.9),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.upload_outlined,
                    size: 100,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputMessageWidget(BuildContext context) {
    return Container(
      decoration: controller.responsive.isMobile(context)
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
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
            const ConnectionStatusHeader(),
            // Currently we can't support reactions
            // ReactionsPicker(controller),
            const SizedBox(height: 8.0),
            Padding(
              padding: ChatViewBodyStyle.inputBarPadding(context),
              child: ChatInputRow(controller),
            ),
            SizedBox(
              height: controller.responsive.isMobile(context) ? 8.0 : 8.0,
            ),
          ].map(
            (widget) => widget,
          ),
          if (!controller.responsive.isMobile(context))
            ChatEmojiPicker(
              showEmojiPickerNotifier: controller.showEmojiPickerNotifier,
              onEmojiSelected: controller.onEmojiSelected,
              emojiPickerBackspace: controller.emojiPickerBackspace,
            ),
        ],
      ),
    );
  }
}
