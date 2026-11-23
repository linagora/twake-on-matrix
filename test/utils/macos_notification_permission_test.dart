import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/flutter_local_notifications_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('starting the notification port does not ask the permission', () async {
    await FlutterLocalNotificationsPort().init((_) {});

    final init = calls.singleWhere((c) => c.method == 'initialize');
    final args = Map<String, dynamic>.from(init.arguments as Map);
    expect(args['requestAlertPermission'], isFalse);
    expect(args['requestBadgePermission'], isFalse);
    expect(args['requestSoundPermission'], isFalse);
    expect(calls.map((c) => c.method), isNot(contains('requestPermissions')));
  });

  test(
    'the permission is asked on demand, once the user is logged in',
    () async {
      final port = FlutterLocalNotificationsPort();
      await port.init((_) {});
      await port.requestPermission();

      expect(calls.map((c) => c.method), contains('requestPermissions'));
    },
  );
}
