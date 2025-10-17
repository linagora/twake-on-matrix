import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_permissions_settings/chat_permissions_settings.dart';
import 'package:fluffychat/pages/chat_permissions_settings/permission_list_tile.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

class ChatPermissionsSettingsView extends StatelessWidget {
  final ChatPermissionsSettingsController controller;

  const ChatPermissionsSettingsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GoRouterState.of(context).path?.startsWith('/spaces/') == true
            ? null
            : IconButton(
                icon: const Icon(Icons.close_outlined),
                onPressed: () => context.go('/rooms/${controller.roomId!}'),
              ),
        title: Text(L10n.of(context)!.editChatPermissions),
      ),
      body: MaxWidthBody(
        withScrolling: true,
        child: StreamBuilder(
          stream: controller.onChanged,
          builder: (context, _) {
            final roomId = controller.roomId;
            final room = roomId == null
                ? null
                : Matrix.of(context).client.getRoomById(roomId);
            if (room == null) {
              return Center(child: Text(L10n.of(context)!.noRoomsFound));
            }
            final powerLevelsContent = Map<String, dynamic>.from(
              room.getState(EventTypes.RoomPowerLevels)!.content,
            );
            final powerLevels = Map<String, dynamic>.from(powerLevelsContent)
              ..removeWhere((k, v) => v is! int);
            final eventsPowerLevels =
                Map<String, dynamic>.from(powerLevelsContent['events'] ?? {})
                  ..removeWhere((k, v) => v is! int);
            return Column(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in powerLevels.entries)
                      PermissionsListTile(
                        permissionKey: entry.key,
                        permission: entry.value,
                        onTap: () => controller.editPowerLevel(
                          context,
                          entry.key,
                          entry.value,
                        ),
                      ),
                    const Divider(thickness: 1),
                    ListTile(
                      title: Text(
                        L10n.of(context)!.notifications,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        const key = 'rooms';
                        final int value = powerLevelsContent
                                .containsKey('notifications')
                            ? powerLevelsContent['notifications']['rooms'] ?? 0
                            : 0;
                        return PermissionsListTile(
                          permissionKey: key,
                          permission: value,
                          category: 'notifications',
                          onTap: () => controller.editPowerLevel(
                            context,
                            key,
                            value,
                            category: 'notifications',
                          ),
                        );
                      },
                    ),
                    const Divider(thickness: 1),
                    ListTile(
                      title: Text(
                        L10n.of(context)!.configureChat,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (final entry in eventsPowerLevels.entries)
                      PermissionsListTile(
                        permissionKey: entry.key,
                        category: 'events',
                        permission: entry.value,
                        onTap: () => controller.editPowerLevel(
                          context,
                          entry.key,
                          entry.value,
                          category: 'events',
                        ),
                      ),
                    if (room.canSendEvent(EventTypes.RoomTombstone)) ...{
                      const Divider(thickness: 1),
                      FutureBuilder<Capabilities>(
                        future: room.client.getCapabilities(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            );
                          }
                          final Object roomVersion = room
                                  .getState(EventTypes.RoomCreate)!
                                  .content['room_version'] ??
                              '1';

                          return ListTile(
                            title: Text(
                              '${L10n.of(context)!.roomVersion}: $roomVersion',
                            ),
                            onTap: () =>
                                controller.updateRoomAction(snapshot.data!),
                          );
                        },
                      ),
                    },
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
