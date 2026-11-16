import 'dart:io';
import 'package:twake_chat/domain/model/room/room_extension.dart';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';

extension LocalNotificationsExtension on MatrixState {
  void showLocalNotification(EventUpdate eventUpdate) async {
    final roomId = eventUpdate.roomID;
    if (activeRoomId == roomId) {
      if (PlatformInfos.isLinux && DesktopLifecycle.instance.isActive.value) {
        return;
      }
    }
    final room = client.getRoomById(roomId);
    if (room == null) {
      Logs().w('Can not display notification for unknown room $roomId');
      return;
    }
    if (room.notificationCount == 0 ||
        (room.isMuted && room.highlightCount == 0)) {
      return;
    }
    final event = Event.fromJson(eventUpdate.content, room);
    final title = room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)!));
    final body = await event.calcLocalizedBody(
      MatrixLocals(L10n.of(context)!),
      withSenderNamePrefix:
          !room.isDirectChat || room.lastEvent?.senderId == client.userID,
      plaintextBody: true,
      hideReply: true,
      hideEdit: true,
      removeMarkdown: true,
    );
    if (Platform.isLinux) {
      final appIconUrl = room.avatar?.getThumbnail(
        room.client,
        width: 56,
        height: 56,
      );
      File? appIconFile;
      if (appIconUrl != null) {
        final tempDirectory = await getApplicationSupportDirectory();
        final avatarDirectory = await Directory(
          '${tempDirectory.path}/notiavatars/',
        ).create();
        appIconFile = File(
          '${avatarDirectory.path}/${Uri.encodeComponent(appIconUrl.toString())}',
        );
        if (await appIconFile.exists() == false) {
          final response = await http.get(appIconUrl);
          await appIconFile.writeAsBytes(response.bodyBytes);
        }
      }
      final notification = await linuxNotifications!.notify(
        title,
        body: body,
        replacesId: linuxNotificationIds[roomId] ?? 0,
        appName: AppConfig.applicationName,
        appIcon: appIconFile?.path ?? '',
        actions: [
          NotificationAction(
            DesktopNotificationActions.openChat.name,
            L10n.of(context)!.openChat,
          ),
          NotificationAction(
            DesktopNotificationActions.seen.name,
            L10n.of(context)!.markAsRead,
          ),
        ],
        hints: [NotificationHint.soundName('message-new-instant')],
      );
      notification.action.then((actionStr) {
        final action = DesktopNotificationActions.values.singleWhere(
          (a) => a.name == actionStr,
        );
        switch (action) {
          case DesktopNotificationActions.seen:
            room.setReadMarker(event.eventId, mRead: event.eventId);
            break;
          case DesktopNotificationActions.openChat:
            RoomRoute(roomid: room.id).go(context);
            break;
        }
      });
      linuxNotificationIds[roomId] = notification.id;
    }
  }
}

enum DesktopNotificationActions { seen, openChat }
