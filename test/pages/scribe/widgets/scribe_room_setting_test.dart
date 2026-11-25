import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/scribe/widgets/scribe_room_setting.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

const _roomId = '!room:example.com';
const _configured = DriveConfig(
  ssoUrl: 'https://sso.example',
  ssoClientId: 'c',
);
const _ownedGroup = ScribeRoom(
  isEncrypted: true,
  isDirect: false,
  scribeEnabled: false,
  isOwner: true,
);

class _RoomSource implements ScribeRoomSource {
  _RoomSource(ScribeRoom room) : _room = room;

  ScribeRoom _room;
  final _updates = StreamController<ScribeRoom>.broadcast();
  final writes = <bool>[];
  bool failWrites = false;

  Stream<ScribeRoom>? watched;

  Completer<void>? heldWrite;

  void sync(ScribeRoom room) {
    _room = room;
    _updates.add(room);
  }

  @override
  Stream<ScribeRoom> watchRoom(String roomId) async* {
    final watched = this.watched;
    if (watched != null) {
      yield* watched;
      return;
    }
    yield _room;
    yield* _updates.stream;
  }

  @override
  Future<void> setScribeEnabled(String roomId, {required bool enabled}) async {
    writes.add(enabled);
    await heldWrite?.future;
    if (failWrites) throw const ScribeSwitchFailed();
  }
}

void main() {
  setUp(() => getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils()));
  tearDown(() async => getIt.reset());

  final hiddenIn = <String, _RoomSource Function()>{
    'a clear room': () => _RoomSource(
      const ScribeRoom(
        isEncrypted: false,
        isDirect: false,
        scribeEnabled: false,
      ),
    ),
    'an encrypted direct chat': () => _RoomSource(
      const ScribeRoom(isEncrypted: true, isDirect: true, scribeEnabled: false),
    ),
    'a room still loading': () =>
        _RoomSource(_ownedGroup)
          ..watched = StreamController<ScribeRoom>().stream,
    'a room that cannot be read': () =>
        _RoomSource(_ownedGroup)
          ..watched = Stream.error(const ScribeRoomNotFound()),
  };
  for (final MapEntry(key: room, value: sourceOf) in hiddenIn.entries) {
    testWidgets('is hidden in $room', (tester) async {
      await _pumpSetting(tester, sourceOf());

      expect(find.byType(LinagoraSettingItem), findsNothing);
    });
  }

  testWidgets('a member reads the state but cannot change it', _memberTest);
  testWidgets(
    'the owner turns it on; the switch waits for the write',
    _ownerTest,
  );
  testWidgets('a refused change goes back and says so', _refusedTest);
  testWidgets('a refusal after the screen closed changes nothing', _closedTest);
}

Future<void> _pumpSetting(WidgetTester tester, _RoomSource source) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driveConfigProvider.overrideWithValue(_configured),
        scribeRoomSourceProvider.overrideWithValue(source),
      ],
      child: const MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(body: ScribeRoomSetting(roomId: _roomId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LinagoraSettingItem _setting(WidgetTester tester) =>
    tester.widget(find.byType(LinagoraSettingItem));

Future<void> _memberTest(WidgetTester tester) async {
  await _pumpSetting(
    tester,
    _RoomSource(_ownedGroup.copyWith(isOwner: false, scribeEnabled: true)),
  );

  expect(_setting(tester).value, isTrue);
  expect(_setting(tester).enabled, isFalse);
}

Future<void> _ownerTest(WidgetTester tester) async {
  final source = _RoomSource(_ownedGroup)..heldWrite = Completer();
  await _pumpSetting(tester, source);

  _setting(tester).onChanged!(true);
  await tester.pump();

  expect(source.writes, [true]);
  expect(_setting(tester).value, isTrue);
  expect(_setting(tester).enabled, isFalse);

  source.heldWrite!.complete();
  await tester.pumpAndSettle();

  expect(_setting(tester).value, isTrue);
  expect(_setting(tester).enabled, isTrue);

  source.sync(_ownedGroup.copyWith(scribeEnabled: true));
  await tester.pumpAndSettle();

  expect(_setting(tester).value, isTrue);
  expect(_setting(tester).enabled, isTrue);
}

Future<void> _refusedTest(WidgetTester tester) async {
  final source = _RoomSource(_ownedGroup)..failWrites = true;
  await _pumpSetting(tester, source);

  _setting(tester).onChanged!(true);
  await tester.pumpAndSettle();

  expect(_setting(tester).value, isFalse);
  expect(_setting(tester).enabled, isTrue);
  expect(find.text("Couldn't change Scribe. Try again."), findsOneWidget);
}

Future<void> _closedTest(WidgetTester tester) async {
  final source = _RoomSource(_ownedGroup)
    ..failWrites = true
    ..heldWrite = Completer();
  await _pumpSetting(tester, source);

  _setting(tester).onChanged!(true);
  await tester.pump();
  await tester.pumpWidget(const SizedBox());
  source.heldWrite!.complete();
  await tester.pump();

  expect(tester.takeException(), isNull);
}
