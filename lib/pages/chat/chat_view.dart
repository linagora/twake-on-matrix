import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_invitation_body.dart';
import 'package:fluffychat/pages/chat/chat_view_body.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

enum _EventContextAction { info, report }

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
                .actionWithClearSelections(controller.copySingleEventAction),
          ),
          // #777 Hide Delete Message functionality
          // if (controller.canRedactSelectedEvents)
          //   TwakeIconButton(
          //     icon: Icons.delete_outlined,
          //     tooltip: L10n.of(context)!.redactMessage,
          //     onTap: () => controller
          //         .actionWithClearSelections(controller.redactEventsAction),
          //   ),
          if (controller.selectedEvents.length == 1)
            TwakeIconButton(
              icon: Icons.push_pin_outlined,
              tooltip: L10n.of(context)!.pinChat,
              onTap: () => controller.actionWithClearSelections(
                () => controller.pinEventAction(
                  controller.selectedEvents.single,
                ),
              ),
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

    return StreamBuilder(
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
                      child: ChatAppBarTitle(
                        selectedEvents: controller.selectedEvents,
                        room: controller.room,
                        isArchived: controller.isArchived,
                        sendController: controller.sendController,
                        connectivityResultStream: controller
                            .networkConnectionService
                            .getStreamInstance(),
                        actions: _appBarActions(context),
                        onPushDetails: controller.onPushDetails,
                        roomName: controller.roomName,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!controller.selectMode)
                  Padding(
                    padding: ChatViewStyle.paddingTrailing(context),
                    child: IconButton(
                      onPressed: controller.toggleSearch,
                      icon: const Icon(Icons.search),
                    ),
                  ),
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
                    controller.selectedEvents.isEmpty &&
                    controller.replyEvent == null) {
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
            body: _buildBody(),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (controller.room == null) {
      return const SizedBox.shrink();
    }

    if (controller.room!.membership == Membership.invite) {
      return ChatInvitationBody(controller);
    }

    return ChatViewBody(controller);
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
    return const SizedBox.shrink();
  }
}
