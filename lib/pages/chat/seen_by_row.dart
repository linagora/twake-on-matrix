import 'package:flutter/material.dart';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/utils/room_status_extension.dart';

class SeenByRow extends StatelessWidget {
  final ChatController controller;
  final String? eventId;

  const SeenByRow(this.controller, {this.eventId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seenByUsers = controller.room!.getSeenByUsers(
      controller.timeline!,
      eventId: eventId,
    );
    // const maxAvatars = 7;
    return seenByUsers.isEmpty
        ? Image.asset(
            'assets/ic_send_status.png',
            color: Theme.of(context).colorScheme.secondary,
            width: 16,
            height: 16,
          )
        : Image.asset(
            'assets/ic_read_status.png',
            color: Theme.of(context).colorScheme.onSecondary,
            width: 16,
            height: 16,
          );
    // return Container(
    //   width: double.infinity,
    //   alignment: Alignment.center,
    //   child: AnimatedContainer(
    //     constraints:
    //         const BoxConstraints(maxWidth: FluffyThemes.columnWidth * 2.5),
    //     height: seenByUsers.isEmpty ? 0 : 24,
    //     duration: seenByUsers.isEmpty
    //         ? Duration.zero
    //         : FluffyThemes.animationDuration,
    //     curve: FluffyThemes.animationCurve,
    //     alignment: controller.timeline!.events.isNotEmpty &&
    //             controller.timeline!.events.first.senderId ==
    //                 Matrix.of(context).client.userID
    //         ? Alignment.topRight
    //         : Alignment.topLeft,
    //     padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
    //     child: Wrap(
    //       spacing: 4,
    //       children: [
    //         ...(seenByUsers.length > maxAvatars
    //                 ? seenByUsers.sublist(0, maxAvatars)
    //                 : seenByUsers)
    //             .map(
    //               (user) => Avatar(
    //                 mxContent: user.avatarUrl,
    //                 name: user.calcDisplayname(),
    //                 size: 16,
    //                 fontSize: 9,
    //               ),
    //             )
    //             .toList(),
    //         if (seenByUsers.length > maxAvatars)
    //           SizedBox(
    //             width: 16,
    //             height: 16,
    //             child: Material(
    //               color: Theme.of(context).colorScheme.background,
    //               borderRadius: BorderRadius.circular(32),
    //               child: Center(
    //                 child: Text(
    //                   '+${seenByUsers.length - maxAvatars}',
    //                   style: const TextStyle(fontSize: 9),
    //                 ),
    //               ),
    //             ),
    //           ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
