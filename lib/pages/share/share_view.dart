import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/pages/forward/recent_chat_list.dart';
import 'package:fluffychat/pages/forward/recent_chat_title.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ShareView extends StatelessWidget {
  const ShareView(this.controller, {super.key});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(),
        child: SearchableAppBar(
          title: L10n.of(context)!.selectChat,
          searchModeNotifier: controller.isSearchModeNotifier,
          textEditingController: controller.textEditingController,
          toggleSearchMode: controller.toggleSearchMode,
          focusNode: controller.searchFocusNode,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const RecentChatsTitle(),
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
        builder: ((context, selectedEvents, child) {
          if (selectedEvents.length != 1) {
            return const SizedBox();
          }

          return child!;
        }),
        child: SizedBox(
          height: ForwardViewStyle.bottomBarHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: TwakeIconButton(
              paddingAll: 0,
              onTap: () => controller.shareTo(
                controller.selectedRoomsNotifier.value.first,
              ),
              tooltip: L10n.of(context)!.send,
              imagePath: ImagePaths.icSend,
              imageSize: ForwardViewStyle.iconSendSize,
            ),
          ),
        ),
      ),
    );
  }
}
