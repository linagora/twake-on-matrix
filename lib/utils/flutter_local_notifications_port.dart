import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twake_chat/utils/macos_message_notifier.dart';

/// [LocalNotificationsPort] on top of `flutter_local_notifications` (macOS).
class FlutterLocalNotificationsPort implements LocalNotificationsPort {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Starts the plugin without asking the permission (see
  /// [requestPermission]); [onTap] gets the tapped notification.
  Future<void> init(void Function(NotificationResponse) onTap) async {
    await _plugin.initialize(
      const InitializationSettings(
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onTap,
    );
  }

  /// Asks the macOS permission: called once the user is logged in.
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) => _plugin.show(
    id,
    title,
    body,
    const NotificationDetails(macOS: DarwinNotificationDetails()),
    payload: payload,
  );
}
