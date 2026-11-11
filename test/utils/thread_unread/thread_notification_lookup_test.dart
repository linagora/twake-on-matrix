import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-07 and THR-M-09: an explicit choice wins over taking part, so a
/// reply of a thread the user chose for notifies (or not) without asking
/// the server whether the user took part (`GET /rooms/…/event/<root>`).
/// Only a thread without any choice needs that answer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockNotificationPlugin();
    _account = ThreadAccount(RecordingHomeserver());
    await _account.receiveRoomState(const []);
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel, null),
  );

  test('no choice: the server is asked whether the user took part', () async {
    await _replyArrivesInForeground();

    expect(_lookups, isNotEmpty);
  });

  for (final pref in WirePref.values) {
    test('« ${pref.name} », never written in: a reply asks the server '
        'nothing', () async {
      await _account.receiveThreadPrefs([prefEntry(lunchThread, pref)]);

      await _replyArrivesInForeground();

      expect(_lookups, isEmpty);
    });
  }
}

late ThreadAccount _account;

const _notificationChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// The notification plugin answers as on a device.
void _mockNotificationPlugin() => TestDefaultBinaryMessengerBinding
    .instance
    .defaultBinaryMessenger
    .setMockMethodCallHandler(
      _notificationChannel,
      (call) async => call.method == 'initialize' ? true : null,
    );

Iterable<ServerCall> get _lookups => _account.server.callsTo(lunchRootLookup);

/// Bob replies in the lunch thread while the app is in the foreground, on
/// another screen; whatever the app started meanwhile has run.
Future<void> _replyArrivesInForeground() async {
  await pushHelper(
    PushNotification.fromJson({
      'devices': [],
      'event_id': r'$reply',
      'room_id': teamRoomId,
      'sender': '@bob:example.org',
      'type': EventTypes.Message,
      'content': {
        'msgtype': 'm.text',
        'body': 'count me in',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': lunchThread.rootEventId,
          'is_falling_back': true,
        },
      },
      'counts': {'unread': 1},
    }),
    client: _account,
    l10n: lookupL10n(const Locale('en')),
  );
  await pumpEventQueue();
}
