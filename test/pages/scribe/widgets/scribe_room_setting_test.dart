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

/// A room whose switch the test drives; a write can be made to fail.
class _RoomSource implements ScribeRoomSource {
  _RoomSource(ScribeRoom room) : _room = room;

  ScribeRoom _room;
  final _updates = StreamController<ScribeRoom>.broadcast();
  final writes = <bool>[];
  bool failWrites = false;

  /// Set to keep the room loading or unreadable.
  Stream<ScribeRoom>? watched;

  /// Set to hold a write until the test completes it.
  Completer<void>? heldWrite;

  /// The sync brings the room back.
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

  Future<void> pumpSetting(WidgetTester tester, _RoomSource source) async {
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

  LinagoraSettingItem setting(WidgetTester tester) =>
      tester.widget(find.byType(LinagoraSettingItem));

  testWidgets('is hidden in a clear room', (tester) async {
    await pumpSetting(
      tester,
      _RoomSource(
        const ScribeRoom(
          isEncrypted: false,
          isDirect: false,
          scribeEnabled: false,
        ),
      ),
    );

    expect(find.byType(LinagoraSettingItem), findsNothing);
  });

  testWidgets('is hidden in an encrypted direct chat', (tester) async {
    await pumpSetting(
      tester,
      _RoomSource(
        const ScribeRoom(
          isEncrypted: true,
          isDirect: true,
          scribeEnabled: false,
        ),
      ),
    );

    expect(find.byType(LinagoraSettingItem), findsNothing);
  });

  testWidgets('is hidden while the room loads', (tester) async {
    await pumpSetting(
      tester,
      _RoomSource(_ownedGroup)..watched = StreamController<ScribeRoom>().stream,
    );

    expect(find.byType(LinagoraSettingItem), findsNothing);
  });

  testWidgets('is hidden when the room cannot be read', (tester) async {
    await pumpSetting(
      tester,
      _RoomSource(_ownedGroup)
        ..watched = Stream.error(const ScribeRoomNotFound()),
    );

    expect(find.byType(LinagoraSettingItem), findsNothing);
  });

  testWidgets('a member reads the state but cannot change it', (tester) async {
    await pumpSetting(
      tester,
      _RoomSource(_ownedGroup.copyWith(isOwner: false, scribeEnabled: true)),
    );

    expect(setting(tester).value, isTrue);
    expect(setting(tester).enabled, isFalse);
  });

  testWidgets('the owner turns it on; the switch waits for the sync', (
    tester,
  ) async {
    final source = _RoomSource(_ownedGroup);
    await pumpSetting(tester, source);

    setting(tester).onChanged!(true);
    await tester.pumpAndSettle();

    expect(source.writes, [true]);
    expect(setting(tester).value, isTrue);
    expect(setting(tester).enabled, isFalse);

    source.sync(_ownedGroup.copyWith(scribeEnabled: true));
    await tester.pumpAndSettle();

    expect(setting(tester).value, isTrue);
    expect(setting(tester).enabled, isTrue);
  });

  testWidgets('a refused change goes back and says so', (tester) async {
    final source = _RoomSource(_ownedGroup)..failWrites = true;
    await pumpSetting(tester, source);

    setting(tester).onChanged!(true);
    await tester.pumpAndSettle();

    expect(setting(tester).value, isFalse);
    expect(setting(tester).enabled, isTrue);
    expect(find.text("Couldn't change Scribe. Try again."), findsOneWidget);
  });

  testWidgets('a refusal after the screen closed changes nothing', (
    tester,
  ) async {
    final source = _RoomSource(_ownedGroup)
      ..failWrites = true
      ..heldWrite = Completer();
    await pumpSetting(tester, source);

    setting(tester).onChanged!(true);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    source.heldWrite!.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
