import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/room_access/datasources_impl/room_access_datasource_impl.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';

import 'room_access_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const roomId = '!room:example.com';

  late MockClient client;
  late MockRoom room;
  late CachedStreamController<String> roomUpdates;
  late RoomAccessDatasourceImpl datasource;

  setUp(() {
    client = MockClient();
    room = MockRoom();
    roomUpdates = CachedStreamController();
    when(client.getRoomById(roomId)).thenReturn(room);
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(room.onUpdate).thenReturn(roomUpdates);
    when(room.canChangeJoinRules).thenReturn(true);
    when(room.isDirectChat).thenReturn(false);
    when(room.encrypted).thenReturn(false);
    when(room.joinRules).thenReturn(JoinRules.knock);
    when(
      client.getRoomVisibilityOnDirectory(roomId),
    ).thenAnswer((_) async => Visibility.public);
    datasource = RoomAccessDatasourceImpl(client);
  });

  test('watchRoomAccess_atStart_readsTheRuleAndTheListing', () async {
    // Act
    final access = await datasource.watchRoomAccess(roomId).first;

    // Assert
    expect(
      access,
      const RoomAccess(
        joinRule: JoinRuleChoice.knock,
        isListed: true,
        isEncrypted: false,
        canChange: true,
        hasPublicPage: false,
      ),
    );
  });

  test('watchRoomAccess_whenEncryptionTurnsOn_emitsAgain', () async {
    // Arrange
    final emitted = <RoomAccess>[];
    final subscription = datasource.watchRoomAccess(roomId).listen(emitted.add);
    await pumpEventQueue();

    // Act
    roomUpdates.add(roomId);
    await pumpEventQueue();
    when(room.encrypted).thenReturn(true);
    roomUpdates.add(roomId);
    await pumpEventQueue();

    // Assert
    expect(emitted.map((access) => access.isEncrypted), [false, true]);
    verify(client.getRoomVisibilityOnDirectory(roomId)).called(2);
    unawaited(subscription.cancel());
  });

  test('watchRoomAccess_restrictedRoom_hasNoRuleChoice', () async {
    // Arrange
    when(room.joinRules).thenReturn(JoinRules.restricted);

    // Act
    final access = await datasource.watchRoomAccess(roomId).first;

    // Assert
    expect(access.joinRule, isNull);
  });

  test('watchRoomAccess_unreadableDirectory_countsAsNotListed', () async {
    // Arrange
    when(
      client.getRoomVisibilityOnDirectory(roomId),
    ).thenThrow(MatrixException.fromJson({'errcode': 'M_UNKNOWN'}));

    // Act
    final access = await datasource.watchRoomAccess(roomId).first;

    // Assert
    expect(access.isListed, isFalse);
  });

  test('watchRoomAccess_bugWhileReadingTheDirectory_isNotHidden', () async {
    // Arrange
    when(
      client.getRoomVisibilityOnDirectory(roomId),
    ).thenAnswer((_) async => throw StateError('bug'));

    // Act
    final result = datasource.watchRoomAccess(roomId).first;

    // Assert
    await expectLater(result, throwsA(isA<StateError>()));
  });

  test('watchRoomAccess_directChat_cannotChangeNorReadsTheDirectory', () async {
    // Arrange
    when(room.isDirectChat).thenReturn(true);

    // Act
    final access = await datasource.watchRoomAccess(roomId).first;

    // Assert
    expect(access.canChange, isFalse);
    verifyNever(client.getRoomVisibilityOnDirectory(any));
  });

  test('watchRoomAccess_unknownRoom_throwsNotFound', () async {
    // Arrange
    when(client.getRoomById(roomId)).thenReturn(null);

    // Act
    final result = datasource.watchRoomAccess(roomId).first;

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessRoomNotFoundException>()));
  });

  test('watchRoomAccess_withPublicPage_saysSo', () async {
    // Arrange
    when(room.getState('app.twake.chat.public_page')).thenReturn(
      StrippedStateEvent(
        type: 'app.twake.chat.public_page',
        content: {'enabled': true},
        senderId: '@admin:example.com',
        stateKey: '',
      ),
    );

    // Act
    final access = await datasource.watchRoomAccess(roomId).first;

    // Assert
    expect(access.hasPublicPage, isTrue);
  });

  for (final (choice, rule) in [
    (JoinRuleChoice.invite, JoinRules.invite),
    (JoinRuleChoice.knock, JoinRules.knock),
    (JoinRuleChoice.public, JoinRules.public),
  ]) {
    test('setJoinRule_${choice.name}_sendsThe${rule.name}Rule', () async {
      // Act
      await datasource.setJoinRule(roomId, choice);

      // Assert
      verify(room.setJoinRules(rule)).called(1);
    });
  }

  test('setListed_true_publishesTheRoom', () async {
    // Act
    await datasource.setListed(roomId, isListed: true);

    // Assert
    verify(
      client.setRoomVisibilityOnDirectory(
        roomId,
        visibility: Visibility.public,
      ),
    ).called(1);
  });

  test('setListed_false_unpublishesTheRoom', () async {
    // Act
    await datasource.setListed(roomId, isListed: false);

    // Assert
    verify(
      client.setRoomVisibilityOnDirectory(
        roomId,
        visibility: Visibility.private,
      ),
    ).called(1);
  });

  for (final (name, refusal) in [
    ('forbidden', '{"errcode":"M_FORBIDDEN"}'),
    ('refusedByPublicationRules', '{"errcode":"M_UNKNOWN"}'),
  ]) {
    test('setListed_${name}_throwsForbidden', () async {
      // Arrange
      when(
        client.setRoomVisibilityOnDirectory(
          roomId,
          visibility: anyNamed('visibility'),
        ),
      ).thenThrow(MatrixException(http.Response(refusal, 403)));

      // Act
      final result = datasource.setListed(roomId, isListed: true);

      // Assert
      await expectLater(result, throwsA(isA<RoomAccessForbiddenException>()));
    });
  }

  test('setJoinRule_otherError_throwsSaveFailed', () async {
    // Arrange
    when(room.setJoinRules(any)).thenThrow(Exception('network'));

    // Act
    final result = datasource.setJoinRule(roomId, JoinRuleChoice.invite);

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessSaveFailedException>()));
  });

  test('setJoinRule_programmingError_isNotWrapped', () async {
    // Arrange
    when(room.setJoinRules(any)).thenThrow(StateError('bug'));

    // Act
    final result = datasource.setJoinRule(roomId, JoinRuleChoice.invite);

    // Assert
    await expectLater(result, throwsA(isA<StateError>()));
  });
}
