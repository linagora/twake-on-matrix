import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_loading_view.dart';
import 'package:fluffychat/pages/chat/chat_search_bottom_view.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/pages/chat/pinned_events.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/pages/chat/tombstone_display.dart';
import 'package:fluffychat/widgets/connection_status_header.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../../utils/stream_extension.dart';
import 'chat_emoji_picker.dart';
import 'chat_input_row.dart';

enum _EventContextAction { info, report }

enum _RoomContextAction { search }

class ChatView extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatView(this.controller, {Key? key}) : super(key: key);

  Widget _appBarActions(BuildContext context) {
    if (controller.selectMode) {
      return Row(
        children: [
          // FIXME: 7Aug2023: Need user story for edit message
          TwakeIconButton(
            icon: Icons.copy_outlined,
            tooltip: L10n.of(context)!.copy,
            onTap: () => controller
                .actionWithClearSelections(controller.copyEventsAction),
          ),
          if (controller.canRedactSelectedEvents)
            TwakeIconButton(
              icon: Icons.delete_outlined,
              tooltip: L10n.of(context)!.redactMessage,
              onTap: () => controller
                  .actionWithClearSelections(controller.redactEventsAction),
            ),
          TwakeIconButton(
            icon: Icons.push_pin_outlined,
            tooltip: L10n.of(context)!.pinMessage,
            onTap: () =>
                controller.actionWithClearSelections(controller.pinEventAction),
          ),
          if (controller.selectedEvents.length == 1)
            PopupMenuButton<_EventContextAction>(
              onSelected: (action) {
                switch (action) {
                  case _EventContextAction.info:
                    controller.actionWithClearSelections(
                      () => showEventInfo(
                        context,
                        controller.selectedEvents.single,
                      ),
                    );
                    break;
                  case _EventContextAction.report:
                    controller.actionWithClearSelections(
                      controller.reportEventAction,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _EventContextAction.info,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outlined),
                      const SizedBox(width: 12),
                      Text(L10n.of(context)!.messageInfo),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _EventContextAction.report,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(L10n.of(context)!.reportMessage),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    } else if (controller.isArchived) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton.icon(
          onPressed: controller.forgetRoom,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(L10n.of(context)!.delete),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.matrix ??= Matrix.of(context);
    final client = controller.matrix!.client;
    controller.sendingClient ??= client;
    controller.room = controller.sendingClient!.getRoomById(controller.roomId!);
    if (controller.room == null) {
      return const SizedBox.shrink();
    }

    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    return GestureDetector(
      onTapDown: controller.setReadMarker,
      behavior: HitTestBehavior.opaque,
      child: StreamBuilder(
        stream: controller.room!.onUpdate.stream
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, snapshot) => FutureBuilder<bool>(
          future: controller.getTimeline(),
          builder: (BuildContext context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: ChatViewStyle.toolbarHeight(context),
                surfaceTintColor: Colors.transparent,
                titleSpacing: 0,
                title: Padding(
                  padding: ChatViewStyle.paddingLeading(context),
                  child: Row(
                    children: [
                      _buildLeading(context),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: controller.isSearchingNotifier,
                          builder: (context, isSearching, child) {
                            if (isSearching) {
                              return TextField(
                                controller: controller.searchTextController,
                                focusNode: controller.searchFocusNode,
                                autofocus: true,
                                onChanged: controller.onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: L10n.of(context)!.search,
                                  border: InputBorder.none,
                                  suffixIcon: ValueListenableBuilder(
                                    valueListenable:
                                        controller.searchTextController,
                                    builder: (context, value, child) => value
                                            .text.isNotEmpty
                                        ? IconButton(
                                            onPressed: controller.clearSearch,
                                            icon: const Icon(Icons.close),
                                          )
                                        : const SizedBox(),
                                  ),
                                ),
                              );
                            }
                            return ChatAppBarTitle(
                              selectedEvents: controller.selectedEvents,
                              room: controller.room,
                              isArchived: controller.isArchived,
                              sendController: controller.sendController,
                              getStreamInstance: controller
                                  .networkConnectionService
                                  .getStreamInstance(),
                              actions: _appBarActions(context),
                              onPushDetails: controller.onPushDetails,
                              roomName: controller.roomName,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!controller.selectMode)
                    _SearchMenuItem(controller: controller),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size(double.infinity, 4),
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceTint
                        .withOpacity(0.08),
                    height: 1,
                  ),
                ),
              ),
              floatingActionButton: ValueListenableBuilder(
                valueListenable: controller.showScrollDownButtonNotifier,
                builder: (context, showScrollDownButton, _) {
                  if (showScrollDownButton &&
                      controller.selectedEvents.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 56.0),
                      child: FloatingActionButton(
                        onPressed: controller.scrollDown,
                        mini: true,
                        child: const Icon(Icons.arrow_downward_outlined),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
              body: DropTarget(
                onDragDone: controller.onDragDone,
                onDragEntered: controller.onDragEntered,
                onDragExited: controller.onDragExited,
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
                    SafeArea(
                      child: Column(
                        children: <Widget>[
                          TombstoneDisplay(controller),
                          PinnedEvents(controller),
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.clearSingleSelectedEvent,
                              child: Builder(
                                builder: (context) {
                                  if (controller.timeline == null) {
                                    return const ChatLoadingView();
                                  }
                                  return ChatEventList(
                                    controller: controller,
                                  );
                                },
                              ),
                            ),
                          ),
                          if (controller.room!.membership == Membership.invite)
                            _inputMessageOrSearchBottomWidget(
                              bottomSheetPadding,
                            ),
                          if (controller.room!.canSendDefaultMessages &&
                              controller.room!.membership == Membership.join)
                            Container(
                              constraints: const BoxConstraints(
                                maxWidth: FluffyThemes.columnWidth * 2.5,
                              ),
                              alignment: Alignment.center,
                              child: controller.room?.isAbandonedDMRoom == true
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                        bottom: bottomSheetPadding,
                                        left: bottomSheetPadding,
                                        right: bottomSheetPadding,
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
                                            onPressed: controller.leaveChat,
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
                                  : _inputMessageOrSearchBottomWidget(
                                      bottomSheetPadding,
                                    ),
                            ),
                        ],
                      ),
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
          },
        ),
      ),
    );
  }

  Widget _inputMessageOrSearchBottomWidget(double bottomSheetPadding) =>
      ValueListenableBuilder(
        valueListenable: controller.isSearchingNotifier,
        builder: (context, isSearching, child) => isSearching
            ? ChatSearchBottomView(controller: controller)
            : _inputMessageWidget(bottomSheetPadding),
      );

  Widget _inputMessageWidget(double bottomSheetPadding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[
          const ConnectionStatusHeader(),
          // Currently we can't support reactions
          // ReactionsPicker(controller),
          ReplyDisplay(controller),
          ChatInputRow(controller),
        ].map(
          (widget) => Padding(
            padding: EdgeInsets.only(
              left: bottomSheetPadding,
              right: bottomSheetPadding,
            ),
            child: widget,
          ),
        ),
        SizedBox(height: bottomSheetPadding),
        ChatEmojiPicker(controller),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) => TwakeIconButton(
        tooltip: L10n.of(context)!.back,
        icon: Icons.arrow_back,
        onTap: controller.onBackPress,
        paddingAll: 8.0,
        margin: const EdgeInsets.symmetric(vertical: 12.0),
      );

  Widget _buildLeading(BuildContext context) {
    if (controller.selectMode) {
      return TwakeIconButton(
        icon: Icons.close,
        onTap: controller.clearSelectedEvents,
        tooltip: L10n.of(context)!.close,
      );
    }
    if (controller.responsive.isMobile(context)) {
      return _buildBackButton(context);
    }
    return ValueListenableBuilder(
      valueListenable: controller.isSearchingNotifier,
      builder: (context, isSearching, child) {
        if (isSearching) {
          return _buildBackButton(context);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SearchMenuItem extends StatelessWidget {
  const _SearchMenuItem({
    required this.controller,
  });

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.isSearchingNotifier,
      builder: (context, isSearching, child) {
        if (isSearching) {
          return const SizedBox();
        }
        return PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _RoomContextAction.search,
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      L10n.of(context)!.search,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          ],
          onSelected: (item) {
            switch (item) {
              case _RoomContextAction.search:
                return controller.toggleSearch();
            }
          },
        );
      },
    );
  }
}
