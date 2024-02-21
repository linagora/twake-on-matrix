import 'package:fluffychat/pages/forward/forward_view_style.dart';
import 'package:fluffychat/pages/forward/recent_chat_list.dart';
import 'package:fluffychat/pages/forward/recent_chat_title.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class ShareView extends StatelessWidget {
  const ShareView(this.controller, {super.key});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          title: L10n.of(context)!.selectChat,
          searchModeNotifier: controller.isSearchModeNotifier,
          textEditingController: controller.searchTextEditingController,
          openSearchBar: controller.toggleSearchMode,
          closeSearchBar: controller.closeSearchBar,
          focusNode: controller.searchFocusNode,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const RecentChatsTitle(),
              ValueListenableBuilder<List<Room>>(
                valueListenable: controller.recentlyChatsNotifier,
                builder: (context, rooms, child) {
                  if (rooms.isNotEmpty) {
                    return RecentChatList(
                      rooms: rooms,
                      selectedChatNotifier: controller.selectedChatNotifier,
                      onSelectedChat: (roomId) =>
                          controller.onToggleSelectChat(roomId),
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
      floatingActionButton: ValueListenableBuilder<String>(
        valueListenable: controller.selectedChatNotifier,
        builder: ((context, selectedEvents, child) {
          if (selectedEvents.isEmpty) {
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
                controller.selectedChatNotifier.value,
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
