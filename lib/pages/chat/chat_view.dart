import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_invitation_body.dart';
import 'package:fluffychat/pages/chat/chat_view_body.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatView extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatView(this.controller, {super.key});

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
              icon: !controller.isUnpinEvent(controller.selectedEvents.first)
                  ? Icons.push_pin_outlined
                  : null,
              iconColor:
                  controller.isUnpinEvent(controller.selectedEvents.first)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
              imagePath:
                  controller.isUnpinEvent(controller.selectedEvents.first)
                      ? ImagePaths.icUnpin
                      : null,
              tooltip: !controller.isUnpinEvent(controller.selectedEvents.first)
                  ? L10n.of(context)!.pinChat
                  : L10n.of(context)!.unpin,
              onTap: () => controller.actionWithClearSelections(
                () => controller.pinEventAction(
                  controller.selectedEvents.single,
                ),
              ),
              imageSize: ChatViewStyle.appBarIconSize,
            ),
          if (controller.selectedEvents.length == 1)
            TwakeIconButton(
              icon: Icons.more_vert,
              tooltip: L10n.of(context)!.more,
              onTapDown: (tapDownDetails) => controller.handleAppbarMenuAction(
                context,
                tapDownDetails,
              ),
              preferBelow: false,
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

    return Focus(
      focusNode: controller.chatFocusNode,
      child: GestureDetector(
        onTapDown: (_) => controller.setReadMarker(),
        behavior: HitTestBehavior.opaque,
        child: StreamBuilder(
          stream: controller.room!.onUpdate.stream
              .rateLimit(const Duration(seconds: 1)),
          builder: (context, snapshot) => FutureBuilder(
            future: controller.loadTimelineFuture,
            builder: (BuildContext context, snapshot) {
              return Scaffold(
                backgroundColor: controller.responsive.isMobile(context)
                    ? LinagoraSysColors.material().background
                    : LinagoraSysColors.material().onPrimary,
                appBar: AppBar(
                  backgroundColor: controller.responsive.isMobile(context)
                      ? LinagoraSysColors.material().surface
                      : LinagoraSysColors.material().onPrimary,
                  automaticallyImplyLeading: false,
                  toolbarHeight: ChatViewStyle.appBarHeight(context),
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
                                .connectivity
                                .onConnectivityChanged,
                            actions: _appBarActions(context),
                            onPushDetails: controller.onPushDetails,
                            roomName: controller.roomName,
                            cachedPresenceNotifier:
                                controller.cachedPresenceNotifier,
                            cachedPresenceStreamController:
                                controller.cachedPresenceStreamController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (!controller.selectMode)
                      Padding(
                        padding: ChatViewStyle.paddingTrailing(context),
                        child: Row(
                          children: [
                            IconButton(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onPressed: controller.toggleSearch,
                              icon: const Icon(Icons.search),
                            ),
                            if (!controller.room!.isDirectChat)
                              Builder(
                                builder: (context) => TwakeIconButton(
                                  icon: Icons.more_vert,
                                  tooltip: L10n.of(context)!.more,
                                  onTapDown: (tapDownDetails) =>
                                      controller.handleAppbarMenuAction(
                                    context,
                                    tapDownDetails,
                                  ),
                                  preferBelow: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
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
                floatingActionButton: ValueListenableBuilder(
                  valueListenable: controller.showScrollDownButtonNotifier,
                  builder: (context, showScrollDownButton, _) {
                    if (showScrollDownButton &&
                        controller.selectedEvents.isEmpty &&
                        controller.replyEventNotifier.value == null) {
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
        ),
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

    return ValueListenableBuilder(
      valueListenable: controller.replyEventNotifier,
      builder: (context, _, __) {
        return ChatViewBody(controller);
      },
    );
  }

  Widget _buildBackButton(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: TwakeIconButton(
          tooltip: L10n.of(context)!.back,
          icon: Icons.chevron_left_outlined,
          onTap: controller.onBackPress,
          margin: const EdgeInsets.symmetric(vertical: 12.0),
        ),
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
