import 'package:fluffychat/pages/forward/recent_chat_list.dart';
import 'package:fluffychat/pages/forward/recent_chat_title.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class ShareView extends StatelessWidget {
  const ShareView(this.controller, {super.key});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          L10n.of(context)!.share,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        leading: TwakeIconButton(
          tooltip: L10n.of(context)!.cancel,
          icon: Icons.close,
          onTap: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              RecentChatsTitle(
                isShowRecentlyChats:
                    controller.isShowRecentlyChatsNotifier.value,
                toggleRecentChat: controller.toggleRecentlyChats,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: controller.isShowRecentlyChatsNotifier,
                builder: (context, isShowRecentlyChat, child) {
                  if (isShowRecentlyChat) {
                    return RecentChatList(
                      rooms: Matrix.of(context).client.rooms,
                      selectedEventsNotifier: controller.selectedRoomsNotifier,
                      onSelectedChat: (roomId) =>
                          controller.onSelectChat(roomId),
                      recentChatScrollController:
                          controller.recentChatScrollController,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ValueListenableBuilder<List<String>>(
        valueListenable: controller.selectedRoomsNotifier,
        builder: ((context, selectedChats, child) {
          if (selectedChats.length != 1) {
            return const SizedBox.shrink();
          }
          return TwakeFloatingActionButton(
            icon: Icons.send,
            size: 18.0,
            onTap: () => controller.shareTo(
              controller.selectedRoomsNotifier.value.first,
            ),
          );
        }),
      ),
    );
  }
}
