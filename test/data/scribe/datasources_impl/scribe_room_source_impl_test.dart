import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source.provider.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_room_source_impl.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';

import '../../../providers/fake_active_account.dart';
import 'scribe_room_source_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const roomId = '!room:example.com';

  late MockClient client;
  late MockRoom room;
  late CachedStreamController<String> roomUpdates;
  late ScribeRoomSourceImpl source;

  Event scribeState({required bool enabled}) => Event(
    content: {'enabled': enabled},
    type: ScribeRoomSourceImpl.scribeStateType,
    eventId: r'$scribe',
    senderId: '@owner:example.com',
    originServerTs: DateTime.utc(2026),
    stateKey: '',
    room: room,
  );

  setUp(() {
    client = MockClient();
    room = MockRoom();
    roomUpdates = CachedStreamController();
    when(client.getRoomById(roomId)).thenReturn(room);
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(room.onUpdate).thenReturn(roomUpdates);
    when(room.encrypted).thenReturn(true);
    when(room.isDirectChat).thenReturn(false);
    when(room.isSpace).thenReturn(false);
    when(room.canInvite).thenReturn(true);
    when(room.ownPowerLevel).thenReturn(PowerLevel.admin);
    source = ScribeRoomSourceImpl(client);
  });

  group('watchRoom', () {
    test('reads the switch and the owner after loading the state', () async {
      when(
        room.getState(ScribeRoomSourceImpl.scribeStateType),
      ).thenReturn(scribeState(enabled: true));

      final scribeRoom = await source.watchRoom(roomId).first;

      verify(room.postLoad()).called(1);
      expect(
        scribeRoom,
        const ScribeRoom(
          isEncrypted: true,
          isDirect: false,
          scribeEnabled: true,
          isOwner: true,
        ),
      );
    });

    test('a room without the switch has the Scribe off', () async {
      final scribeRoom = await source.watchRoom(roomId).first;

      expect(scribeRoom.scribeEnabled, isFalse);
    });

    test('a moderator is not the owner', () async {
      when(room.ownPowerLevel).thenReturn(PowerLevel.moderator);

      final scribeRoom = await source.watchRoom(roomId).first;

      expect(scribeRoom.isOwner, isFalse);
    });

    test('an admin who may not invite is not the owner', () async {
      when(room.canInvite).thenReturn(false);

      final scribeRoom = await source.watchRoom(roomId).first;

      expect(scribeRoom.isOwner, isFalse);
    });

    test('emits again when the switch changes, not on other updates', () async {
      final emitted = <ScribeRoom>[];
      final subscription = source.watchRoom(roomId).listen(emitted.add);
      await pumpEventQueue();

      roomUpdates.add(roomId);
      await pumpEventQueue();
      when(
        room.getState(ScribeRoomSourceImpl.scribeStateType),
      ).thenReturn(scribeState(enabled: true));
      roomUpdates.add(roomId);
      await pumpEventQueue();

      expect(emitted.map((room) => room.scribeEnabled), [false, true]);
      // The stream waits on the room's updates: its cancel never completes.
      unawaited(subscription.cancel());
    });

    test('an unknown room fails', () async {
      when(client.getRoomById(roomId)).thenReturn(null);

      await expectLater(
        source.watchRoom(roomId).first,
        throwsA(isA<ScribeRoomNotFound>()),
      );
    });
  });

  group('setScribeEnabled', () {
    test('writes the state event Chat web reads', () async {
      when(
        client.setRoomStateWithKey(any, any, any, any),
      ).thenAnswer((_) async => r'$event');

      await source.setScribeEnabled(roomId, enabled: true);

      verify(
        client.setRoomStateWithKey(roomId, 'app.twake.chat.scribe', '', {
          'enabled': true,
        }),
      ).called(1);
    });

    test('a refused write fails the switch', () async {
      when(client.setRoomStateWithKey(any, any, any, any)).thenThrow(
        MatrixException.fromJson({
          'errcode': 'M_FORBIDDEN',
          'error': 'You may not',
        }),
      );

      await expectLater(
        source.setScribeEnabled(roomId, enabled: false),
        throwsA(isA<ScribeSwitchFailed>()),
      );
    });

    test('an unknown room fails before any request', () async {
      when(client.getRoomById(roomId)).thenReturn(null);

      await expectLater(
        source.setScribeEnabled(roomId, enabled: true),
        throwsA(isA<ScribeRoomNotFound>()),
      );
      verifyNever(client.setRoomStateWithKey(any, any, any, any));
    });
  });

  group('scribeRoomSourceProvider', () {
    test(
      'writes on the active account only, before and after a switch',
      () async {
        final other = MockClient();
        final otherRoom = MockRoom();
        when(other.getRoomById(roomId)).thenReturn(otherRoom);
        when(otherRoom.id).thenReturn(roomId);
        when(otherRoom.client).thenReturn(other);
        for (final account in [client, other]) {
          when(
            account.setRoomStateWithKey(any, any, any, any),
          ).thenAnswer((_) async => r'$event');
        }
        final container = ProviderContainer.test(
          overrides: activeAccountOverridesFollowing(),
        );
        final active = container.read(fakeActiveAccountProvider.notifier);
        Future<void> turnOn() => container
            .read(scribeRoomSourceProvider)
            .setScribeEnabled(roomId, enabled: true);

        active.set(client);
        await turnOn();
        active.set(other);
        await turnOn();

        verify(client.setRoomStateWithKey(any, any, any, any)).called(1);
        verify(other.setRoomStateWithKey(any, any, any, any)).called(1);
      },
    );
  });
}
