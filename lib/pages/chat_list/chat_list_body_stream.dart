import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:vrouter/vrouter.dart';

import 'chat_list_body.dart';

class ChatListBodyStream extends StatelessWidget {
  final ChatListController controller;

  const ChatListBodyStream({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final client = Matrix.of(context).client;

    return StreamBuilder<Object?>(
      stream: Matrix.of(context).onShareContentChanged.stream,
      builder: (_, __) {
        return VWidgetGuard(
          onSystemPop: (redirector) async {
            final selMode = controller.selectMode;
            if (selMode != SelectMode.normal) {
              controller.cancelAction();
              redirector.stopRedirection();
              return;
            }
            return;
          },
          child: Row(
            children: [
              if (FluffyThemes.isColumnMode(context) &&
                  FluffyThemes.getDisplayNavigationRail(context)) ...[
                // Builder(
                //   builder: (context) {
                //     final allSpaces =
                //         client.rooms.where((room) => room.isSpace);
                //     final rootSpaces = allSpaces
                //         .where(
                //           (space) => !allSpaces.any(
                //             (parentSpace) => parentSpace.spaceChildren
                //                 .any((child) => child.roomId == space.id),
                //           ),
                //         )
                //         .toList();
                //     final destinations = controller.getNavigationDestinations(context);

                //     return SizedBox(
                //       width: 64,
                //       child: ListView.builder(
                //         scrollDirection: Axis.vertical,
                //         itemCount: rootSpaces.length + destinations.length,
                //         itemBuilder: (context, i) {
                //           if (i < destinations.length) {
                //             return NaviRailItem(
                //               isSelected: i == controller.selectedIndex,
                //               onTap: () => controller.onDestinationSelected(i),
                //               icon: destinations[i].icon,
                //               selectedIcon: destinations[i].selectedIcon,
                //               toolTip: destinations[i].label,
                //             );
                //           }
                //           i -= destinations.length;
                //           final isSelected =
                //               controller.activeFilter == ActiveFilter.spaces &&
                //                   rootSpaces[i].id == controller.activeSpaceId;
                //           return NaviRailItem(
                //             toolTip: rootSpaces[i].getLocalizedDisplayname(
                //               MatrixLocals(L10n.of(context)!),
                //             ),
                //             isSelected: isSelected,
                //             onTap: () =>
                //                 controller.setActiveSpace(rootSpaces[i].id),
                //             icon: Avatar(
                //               mxContent: rootSpaces[i].avatar,
                //               name: rootSpaces[i].getLocalizedDisplayname(
                //                 MatrixLocals(L10n.of(context)!),
                //               ),
                //               size: 32,
                //               fontSize: 12,
                //             ),
                //           );
                //         },
                //       ),
                //     );
                //   },
                // ),
                Container(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: FocusManager.instance.primaryFocus?.unfocus,
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.translucent,
                  child: ChatListViewBody(controller),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
