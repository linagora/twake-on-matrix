import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/room_access/room_access_datasource_impl.dart';
import 'package:twake_chat/domain/exception/room_access/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

import 'room_access_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const roomId = '!room:example.com';

  late MockClient client;
  late MockRoom room;
  late RoomAccessDatasourceImpl datasource;

  setUp(() {
    client = MockClient();
    room = MockRoom();
    when(client.getRoomById(roomId)).thenReturn(room);
    when(room.canChangeJoinRules).thenReturn(true);
    when(room.isDirectChat).thenReturn(false);
    when(room.encrypted).thenReturn(false);
    when(room.joinRules).thenReturn(JoinRules.knock);
    when(
      client.getRoomVisibilityOnDirectory(roomId),
    ).thenAnswer((_) async => Visibility.public);
    datasource = RoomAccessDatasourceImpl(client);
  });

  test('getRoomAccess_always_readsTheRuleAndTheListing', () async {
    // Act
    final access = await datasource.getRoomAccess(roomId);

    // Assert
    expect(
      access,
      const RoomAccess(
        joinRule: JoinRuleChoice.knock,
        isListed: true,
        isEncrypted: false,
        canChange: true,
      ),
    );
  });

  test('getRoomAccess_restrictedRoom_hasNoRuleChoice', () async {
    // Arrange
    when(room.joinRules).thenReturn(JoinRules.restricted);

    // Act
    final access = await datasource.getRoomAccess(roomId);

    // Assert
    expect(access.joinRule, isNull);
  });

  test('getRoomAccess_unreadableDirectory_countsAsNotListed', () async {
    // Arrange
    when(
      client.getRoomVisibilityOnDirectory(roomId),
    ).thenThrow(MatrixException.fromJson({'errcode': 'M_UNKNOWN'}));

    // Act
    final access = await datasource.getRoomAccess(roomId);

    // Assert
    expect(access.isListed, isFalse);
  });

  test('getRoomAccess_directChat_cannotChangeNorReadsTheDirectory', () async {
    // Arrange
    when(room.isDirectChat).thenReturn(true);

    // Act
    final access = await datasource.getRoomAccess(roomId);

    // Assert
    expect(access.canChange, isFalse);
    verifyNever(client.getRoomVisibilityOnDirectory(any));
  });

  test('getRoomAccess_unknownRoom_throwsNotFound', () async {
    // Arrange
    when(client.getRoomById(roomId)).thenReturn(null);

    // Act & Assert
    await expectLater(
      datasource.getRoomAccess(roomId),
      throwsA(isA<RoomAccessRoomNotFoundException>()),
    );
  });

  test('setJoinRule_public_sendsThePublicRule', () async {
    // Act
    await datasource.setJoinRule(roomId, JoinRuleChoice.public);

    // Assert
    verify(room.setJoinRules(JoinRules.public)).called(1);
  });

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

  test('setListed_forbidden_throwsForbidden', () async {
    // Arrange
    when(
      client.setRoomVisibilityOnDirectory(
        roomId,
        visibility: anyNamed('visibility'),
      ),
    ).thenThrow(MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}));

    // Act & Assert
    await expectLater(
      datasource.setListed(roomId, isListed: true),
      throwsA(isA<RoomAccessForbiddenException>()),
    );
  });

  test('setJoinRule_otherError_throwsSaveFailed', () async {
    // Arrange
    when(room.setJoinRules(any)).thenThrow(Exception('network'));

    // Act & Assert
    await expectLater(
      datasource.setJoinRule(roomId, JoinRuleChoice.invite),
      throwsA(isA<RoomAccessSaveFailedException>()),
    );
  });
}
