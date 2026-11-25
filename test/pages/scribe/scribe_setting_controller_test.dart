import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/pages/scribe/scribe_setting_controller.dart';

const _roomId = '!room:example.com';
const _off = ScribeRoom(
  isEncrypted: true,
  isDirect: false,
  scribeEnabled: false,
  isOwner: true,
);

class _Source implements ScribeRoomSource {
  final _rooms = StreamController<ScribeRoom>.broadcast();
  Completer<void> write = Completer();

  void sync(ScribeRoom room) => _rooms.add(room);

  @override
  Stream<ScribeRoom> watchRoom(String roomId) async* {
    yield _off;
    yield* _rooms.stream;
  }

  @override
  Future<void> setScribeEnabled(String roomId, {required bool enabled}) =>
      write.future;
}

void main() {
  late _Source source;
  late ProviderContainer container;
  late ProviderSubscription<ScribeSettingWanted?> wanted;

  setUp(() async {
    source = _Source();
    container = ProviderContainer.test(
      overrides: [scribeRoomSourceProvider.overrideWithValue(source)],
    );
    wanted = container.listen(
      scribeSettingControllerProvider(_roomId),
      (_, _) {},
    );
    container.listen(scribeRoomProvider(_roomId), (_, _) {});
    await container.read(scribeRoomProvider(_roomId).future);
  });

  Future<void> turnOn() => container
      .read(scribeSettingControllerProvider(_roomId).notifier)
      .save(_off, enabled: true);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('holds the asked value while the write runs, then the sync', () async {
    final saving = turnOn();
    expect(wanted.read(), (enabled: true, saving: true));

    source.write.complete();
    await saving;
    expect(wanted.read(), (enabled: true, saving: false));

    source.sync(_off.copyWith(scribeEnabled: true));
    await settle();
    expect(wanted.read(), isNull);
  });

  test('after the write, the next room state wins whatever it says', () async {
    final saving = turnOn();
    source.write.complete();
    await saving;

    source.sync(_off.copyWith(isOwner: false));
    await settle();

    expect(wanted.read(), isNull);
  });

  test('a refused write shows the room again and reaches the caller', () async {
    final saving = turnOn();
    source.write.completeError(const ScribeSwitchFailed());

    await expectLater(saving, throwsA(isA<ScribeSwitchFailed>()));
    expect(wanted.read(), isNull);
  });
}
