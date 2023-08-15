import 'package:animations/animations.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/search_title.dart';
import 'package:fluffychat/pages/chat_list/space_view.dart';
import 'package:fluffychat/pages/chat_list/stories_header.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';

import '../../config/themes.dart';
import '../../widgets/connection_status_header.dart';
import '../../widgets/matrix.dart';

class ChatListViewBody extends StatelessWidget {
  final ChatListController controller;

  const ChatListViewBody(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return PageTransitionSwitcher(
      transitionBuilder: (
        Widget child,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        );
      },
      child: StreamBuilder(
        key: ValueKey(
          client.userID.toString() +
              controller.activeFilter.toString() +
              controller.activeSpaceId.toString(),
        ),
        stream: client.onSync.stream
            .where((s) => s.hasRoomUpdate)
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, _) {
          if (controller.activeFilter == ActiveFilter.spaces &&
              !controller.isSearchMode) {
            return SpaceView(
              controller,
              scrollController: controller.scrollController,
              key: Key(controller.activeSpaceId ?? 'Spaces'),
            );
          }
          if (controller.waitForFirstSync && client.prevBatch != null) {
            final rooms = controller.filteredRoomsForAll;
            const displayStoriesHeader = false;
            if (rooms.isEmpty && !controller.isSearchMode) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 64),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        ImagePaths.icSkeletons,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Profile?>(
                    // ignore: unnecessary_cast
                    future: controller.fetchOwnProfile(client: client),
                    builder: (context, snapshotProfile) {
                      if (snapshotProfile.connectionState !=
                          ConnectionState.done) {
                        return const SizedBox();
                      }
                      final name = snapshotProfile.data?.displayName ?? '👋';
                      return Column(
                        children: [
                          Text(
                            L10n.of(context)!.welcomeToTwake(name),
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 32,
                              top: 8,
                            ),
                            child: Text(
                              L10n.of(context)!.startNewChatMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            }
            return ListView.builder(
              controller: controller.scrollController,
              // add +1 space below in order to properly scroll below the spaces bar
              itemCount: rooms.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //FIXME: https://github.com/linagora/twake-on-matrix/issues/465
                      // if (controller.isSearchMode) ...[
                      //   ..._buildPublicRooms(context, roomSearchResult),
                      //   ..._buildUsers(context, userSearchResult),
                      //   SearchTitle(
                      //     title: L10n.of(context)!.stories,
                      //     icon: const Icon(Icons.camera_alt_outlined),
                      //   ),
                      // ],
                      if (displayStoriesHeader)
                        // ignore: dead_code
                        StoriesHeader(
                          key: const Key('stories_header'),
                          filter: controller.searchChatController.text,
                        ),
                      const ConnectionStatusHeader(),
                      AnimatedContainer(
                        height: controller.isTorBrowser ? 64 : 0,
                        duration: FluffyThemes.animationDuration,
                        curve: FluffyThemes.animationCurve,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: ListTile(
                            leading: const Icon(Icons.vpn_key),
                            title: Text(L10n.of(context)!.dehydrateTor),
                            subtitle: Text(L10n.of(context)!.dehydrateTorLong),
                            trailing: const Icon(Icons.chevron_right_outlined),
                            onTap: controller.dehydrate,
                          ),
                        ),
                      ),
                      if (controller.isSearchMode)
                        SearchTitle(
                          title: L10n.of(context)!.chats,
                          icon: const Icon(Icons.chat_outlined),
                        ),
                    ],
                  );
                }
                i--;
                if (!rooms[i]
                    .getLocalizedDisplayname(MatrixLocals(L10n.of(context)!))
                    .toLowerCase()
                    .contains(
                      controller.searchChatController.text.toLowerCase(),
                    )) {
                  return Container();
                }
                return ChatListItem(
                  rooms[i],
                  key: Key('chat_list_item_${rooms[i].id}'),
                  selected: controller.selectedRoomIds.contains(rooms[i].id),
                  onTap: controller.selectMode == SelectMode.select
                      ? () => controller.toggleSelection(rooms[i].id)
                      : null,
                  onLongPress: () => controller.toggleSelection(rooms[i].id),
                  activeChat: controller.activeChat == rooms[i].id,
                );
              },
            );
          }
          const dummyChatCount = 5;
          final titleColor =
              Theme.of(context).textTheme.bodyLarge!.color!.withAlpha(100);
          final subtitleColor =
              Theme.of(context).textTheme.bodyLarge!.color!.withAlpha(50);
          return ListView.builder(
            key: const Key('dummychats'),
            itemCount: dummyChatCount,
            itemBuilder: (context, i) => Opacity(
              opacity: (dummyChatCount - i) / dummyChatCount,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: titleColor,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: titleColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                    Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: subtitleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: subtitleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ],
                ),
                subtitle: Container(
                  decoration: BoxDecoration(
                    color: subtitleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  height: 12,
                  margin: const EdgeInsets.only(right: 22),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
