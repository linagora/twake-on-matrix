import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
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
import 'package:twake_chat/utils/macos_message_notifier.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';

extension LocalNotificationsExtension on MatrixState {
  /// Whether the app window is in front: the one fact that differs by
  /// platform in the notification decision.
  bool get _appInForeground => PlatformInfos.isLinux
      ? DesktopLifecycle.instance.isActive.value
      : WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  MessageNotificationCandidate _notificationCandidate(
    EventUpdate eventUpdate,
    Room room,
  ) => MessageNotificationCandidate(
    roomId: room.id,
    senderId: eventUpdate.content['sender'] as String? ?? '',
    ownUserId: client.userID,
    eventType: eventUpdate.content['type'] as String? ?? '',
    // switch to unreadBadgeCount once threads land
    notificationCount: room.notificationCount,
    highlightCount: room.highlightCount,
    isRoomMuted: room.isMuted,
    activeRoomId: activeRoomId,
    appInForeground: _appInForeground,
  );

  /// macOS: the text stays out of the notification centre unless the user
  /// opted in. [client] is the account the event came from.
  Future<void> showMacosNotification(
    Client client,
    EventUpdate eventUpdate,
  ) async {
    final port = macosNotifications;
    if (port == null || !mounted) return;
    final shown = await notifyMacosMessage(
      port,
      MacosMessageRequest(
        client: client,
        eventUpdate: eventUpdate,
        l10n: L10n.of(context)!,
        state: MacosNotificationState(
          activeRoomId: activeRoomId,
          appInForeground: _appInForeground,
          // The opt-in setting is not built yet: generic by default.
          showPreview: false,
        ),
      ),
    );
    if (shown && client.userID != null) {
      macosNotifiedRooms[eventUpdate.roomID] = client.userID!;
    }
  }

  /// macOS: removes the notification of the rooms [client] has read.
  Future<void> clearReadMacosNotifications(Client client) async {
    final port = macosNotifications;
    if (port == null) return;
    final read = [
      for (final e in macosNotifiedRooms.entries)
        if (e.value == client.userID &&
            (client.getRoomById(e.key)?.notificationCount ?? 0) == 0)
          e.key,
    ];
    for (final roomId in read) {
      macosNotifiedRooms.remove(roomId);
      await MacosMessageNotifier(
        port,
        receiverId: client.userID ?? '',
        genericBody: '',
      ).cancelRoom(roomId);
    }
  }

  void showLocalNotification(EventUpdate eventUpdate) async {
    final roomId = eventUpdate.roomID;
    final room = client.getRoomById(roomId);
    if (room == null) {
      Logs().w('Can not display notification for unknown room $roomId');
      return;
    }
    final event = Event.fromJson(eventUpdate.content, room);
    final threadRootId = ThreadRules.threadRootOf(event);
    if (threadRootId != null) {
      // Room counters leave thread messages out and the thread counters land
      // after this event: decide from the reply and the follow state.
      if (!await ThreadRules.shouldNotifyThreadReply(
        event,
        followed: client.threadUnread?.followOnceKnown(
          ThreadRef(roomId, threadRootId),
        ),
        choice: client.threadUnread?.prefOf(ThreadRef(roomId, threadRootId)),
        pushActions: client.pushruleEvaluator.match(event),
        activeThread: activeThread,
      )) {
        return;
      }
    } else if (!shouldNotifyMessage(
      _notificationCandidate(eventUpdate, room),
    )) {
      return;
    }
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
            final threadRootId = ThreadRules.threadRootOf(event);
            if (threadRootId == null) {
              room.setMainTimelineReadMarker(event);
            } else {
              room.setThreadReadMarker(event, ThreadRef(room.id, threadRootId));
            }
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
