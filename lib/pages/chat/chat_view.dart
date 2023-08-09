import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_loading_view.dart';
import 'package:fluffychat/pages/chat/pinned_events.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/pages/chat/tombstone_display.dart';
import 'package:fluffychat/widgets/connection_status_header.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';

import '../../utils/stream_extension.dart';
import 'chat_emoji_picker.dart';
import 'chat_input_row.dart';

enum _EventContextAction { info, report }

class ChatView extends StatelessWidget {
  final ChatController controller;

  const ChatView(this.controller, {Key? key}) : super(key: key);

  List<Widget> _appBarActions(BuildContext context) {
    if (controller.selectMode) {
      return [
        if (controller.canEditSelectedEvents)
          TwakeIconButton(
            icon: Icons.edit_outlined,
            tooltip: L10n.of(context)!.edit,
            onPressed: controller.editSelectedEventAction,
          ),
        TwakeIconButton(
          icon: Icons.copy_outlined,
          tooltip: L10n.of(context)!.copy,
          onPressed: controller.copyEventsAction,
        ),
        if (controller.canSaveSelectedEvent)
          // Use builder context to correctly position the share dialog on iPad
          Builder(
            builder: (context) => TwakeIconButton(
              icon: Icons.adaptive.share,
              tooltip: L10n.of(context)!.share,
              onPressed: () => controller.saveSelectedEvent(context),
            ),
          ),
        if (controller.canRedactSelectedEvents)
          TwakeIconButton(
            icon: Icons.delete_outlined,
            tooltip: L10n.of(context)!.redactMessage,
            onPressed: controller.redactEventsAction,
          ),
        TwakeIconButton(
          icon: Icons.push_pin_outlined,
          onPressed: controller.pinEvent,
          tooltip: L10n.of(context)!.pinMessage,
        ),
        if (controller.selectedEvents.length == 1)
          PopupMenuButton<_EventContextAction>(
            onSelected: (action) {
              switch (action) {
                case _EventContextAction.info:
                  controller.showEventInfo();
                  controller.clearSelectedEvents();
                  break;
                case _EventContextAction.report:
                  controller.reportEventAction();
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
      ];
    } else if (controller.isArchived) {
      return [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
            onPressed: controller.forgetRoom,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(L10n.of(context)!.delete),
          ),
        )
      ];
    } else {
      return [
        const SizedBox.shrink()
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.matrix ??= Matrix.of(context);
    final client = controller.matrix!.client;
    controller.sendingClient ??= client;
    controller.room = controller.sendingClient!.getRoomById(controller.roomId!);
    if (controller.room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    if (controller.room!.membership == Membership.invite) {
      showFutureLoadingDialog(
        context: context,
        future: () => controller.room!.join(),
      );
    }
    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    return GestureDetector(
      onTapDown: controller.setReadMarker,
      behavior: HitTestBehavior.opaque,
      child: StreamBuilder(
        stream: controller.room!.onUpdate.stream.rateLimit(const Duration(seconds: 1)),
        builder: (context, snapshot) => FutureBuilder<bool>(
          future: controller.getTimeline(),
          builder: (BuildContext context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: controller.responsive.isMobile(context) ? true : false,
                toolbarHeight: 64,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 8 + 24 + 8,
                leading: _buildLeading(context),
                titleSpacing: 0,
                title: ChatAppBarTitle(controller),
                actions: _appBarActions(context),
                bottom: PreferredSize(
                  preferredSize: const Size(double.infinity, 4),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08),
                    height: 1,),),
              ),
              floatingActionButton: controller.showScrollDownButton &&
                      controller.selectedEvents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 56.0),
                      child: FloatingActionButton(
                        onPressed: controller.scrollDown,
                        mini: true,
                        child: const Icon(Icons.arrow_downward_outlined),
                      ),
                    )
                  : null,
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
                          if (controller.room!.canSendDefaultMessages &&
                              controller.room!.membership == Membership.join)
                            Container(
                              constraints: const BoxConstraints(
                                maxWidth: FluffyThemes.columnWidth * 2.5,
                              ),
                              alignment: Alignment.center,
                              child: controller.room?.isAbandonedDMRoom ==
                                      true
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                        bottom: bottomSheetPadding,
                                        left: bottomSheetPadding,
                                        right: bottomSheetPadding,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  : Column(
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
                                    ),
                            ),
                        ],
                      ),
                    ),
                    if (controller.dragging)
                      Container(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(0.9),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.upload_outlined,
                          size: 100,
                        ),
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

  Widget? _buildLeading(BuildContext context) {
    if (controller.responsive.isMobile(context)) {
      if (controller.selectMode) {
        return TwakeIconButton(
          icon: Icons.close,
          onPressed: controller.clearSelectedEvents,
          tooltip: L10n.of(context)!.close,
        );
      } else {
        return TwakeIconButton(
          tooltip: L10n.of(context)!.back,
          icon: Icons.arrow_back,
          onPressed: () => controller.backToPreviousPage(),
          paddingAll: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 12.0),
        );
      }
    } else {
      return null;
    }
  }
}
