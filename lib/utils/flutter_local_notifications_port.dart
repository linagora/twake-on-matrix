import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twake_chat/utils/macos_message_notifier.dart';

/// [LocalNotificationsPort] on top of `flutter_local_notifications` (macOS).
class FlutterLocalNotificationsPort implements LocalNotificationsPort {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Asks the macOS permission at start; [onTap] gets the tapped notification.
  Future<void> init(void Function(NotificationResponse) onTap) async {
    await _plugin.initialize(
      const InitializationSettings(macOS: DarwinInitializationSettings()),
      onDidReceiveNotificationResponse: onTap,
    );
  }

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
