import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_room_source.dart';
import 'package:twake_chat/domain/scribe/usecases/set_scribe_enabled_usecase.dart';

const _roomId = '!room:example.com';
const _ownedGroup = ScribeRoom(
  isEncrypted: true,
  isDirect: false,
  scribeEnabled: false,
  isOwner: true,
);

class _Source implements ScribeRoomSource {
  final writes = <bool>[];
  Exception? failure;

  @override
  Stream<ScribeRoom> watchRoom(String roomId) => const Stream.empty();

  @override
  Future<void> setScribeEnabled(String roomId, {required bool enabled}) async {
    writes.add(enabled);
    final failure = this.failure;
    if (failure != null) throw failure;
  }
}

void main() {
  late _Source source;
  late SetScribeEnabledUseCase useCase;

  setUp(() {
    source = _Source();
    useCase = SetScribeEnabledUseCase(source);
  });

  test('the owner of an encrypted group writes the switch', () async {
    await useCase.execute(roomId: _roomId, room: _ownedGroup, enabled: true);

    expect(source.writes, [true]);
  });

  for (final (name, room) in [
    ('a member', _ownedGroup.copyWith(isOwner: false)),
    ('a clear room', _ownedGroup.copyWith(isEncrypted: false)),
    ('a direct chat', _ownedGroup.copyWith(isDirect: true)),
  ]) {
    test('$name writes nothing', () async {
      await expectLater(
        useCase.execute(roomId: _roomId, room: room, enabled: true),
        throwsA(isA<ScribeSwitchFailed>()),
      );
      expect(source.writes, isEmpty);
    });
  }

  test('a refused write reaches the caller', () async {
    source.failure = const ScribeRoomNotFound();

    await expectLater(
      useCase.execute(roomId: _roomId, room: _ownedGroup, enabled: true),
      throwsA(isA<ScribeRoomNotFound>()),
    );
  });
}
