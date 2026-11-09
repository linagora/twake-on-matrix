import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'dart:io';
import 'package:twake_chat/presentation/extensions/event_update_extension.dart';
import 'package:flutter/foundation.dart';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js.dart' as js;

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/web_push/web_push.dart';
import 'package:twake_chat/widgets/matrix.dart';

extension LocalNotificationsExtension on MatrixState {
  static final html.AudioElement _audioPlayer = html.AudioElement()
    ..src = 'assets/assets/sounds/WoodenBeaver_stereo_message-new-instant.ogg'
    ..autoplay = true
    ..load();

  void showLocalNotification(EventUpdate eventUpdate) async {
    final roomId = eventUpdate.roomID;
    // On web the settings toggle owns all browser notifications for this tab:
    // active Web Push is handled by push_sw.js; explicit opt-out suppresses the
    // legacy Notification API fallback too.
    if (kIsWeb && (isWebPushActiveSync() || await isWebPushDisabledByUser())) {
      return;
    }
    final room = client.getRoomById(roomId);
    if (room == null) {
      Logs().w('Can not display notification for unknown room $roomId');
      return;
    }
    final event = Event.fromJson(eventUpdate.content, room);
    final threadRootId = event.threadRootId;
    // The room on screen is read live, but not its thread replies.
    if (threadRootId == null &&
        activeRoomId == roomId &&
        PlatformInfos.isLinux &&
        DesktopLifecycle.instance.isActive.value) {
      return;
    }
    if (threadRootId != null) {
      // Room counters leave thread messages out and the thread counters land
      // after this event: decide from the reply and the follow state.
      if (!await ThreadRules.shouldNotifyThreadReply(
        event,
        followed: client.threadUnread?.followOnceKnown(
          ThreadRef(roomId, threadRootId),
        ),
        pushActions: client.pushruleEvaluator.match(event),
        activeThread: activeThread,
      )) {
        return;
      }
    } else if (!ThreadRules.shouldNotifyMainTimelineEvent(room)) {
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
    final icon =
        event.senderFromMemoryOrFallback.avatarUrl?.getThumbnail(
          client,
          width: 64,
          height: 64,
          method: ThumbnailMethod.crop,
        ) ??
        room.avatar?.getThumbnail(
          client,
          width: 64,
          height: 64,
          method: ThumbnailMethod.crop,
        );
    if (kIsWeb) {
      // Displaying a web notification depends on the hosting page (Cozy parent
      // frame, the `handleNotifications` JS hook). When those are absent the
      // interop throws; a notification-display failure must not crash the app
      // (and, as an unhandled async error, fail web integration tests).
      try {
        final isInsideCozy = await CozyConfigManager().isInsideCozy;
        // `play()` returns a Future that rejects under autoplay policies; await
        // (and swallow) it so the rejection is caught here instead of surfacing
        // as an unhandled async error that crashes web integration tests.
        await _audioPlayer.play().catchError((e, s) {
          Logs().w('showLocalNotification: audio playback failed', e, s);
        });
        if (isInsideCozy) {
          CozyConfigManager().sendNotification(title, body);
          return;
        }
        js.context.callMethod("handleNotifications", [
          title,
          body,
          icon,
          eventUpdate.roomID,
          eventUpdate.eventId,
        ]);
      } catch (e, s) {
        Logs().w('showLocalNotification: web notification failed', e, s);
      }
    } else if (Platform.isLinux) {
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
            final threadRootId = event.threadRootId;
            if (threadRootId == null) {
              room.setMainTimelineReadMarker(event.eventId);
            } else {
              room.setThreadReadMarker(
                threadRootId: threadRootId,
                eventId: event.eventId,
              );
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
