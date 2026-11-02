import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/room_access/datasources/room_access_datasource.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository_impl.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

import 'room_access_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoomAccessDatasource>()])
void main() {
  const roomId = '!room:example.com';

  late MockRoomAccessDatasource datasource;
  late RoomAccessRepositoryImpl repository;

  setUp(() {
    datasource = MockRoomAccessDatasource();
    repository = RoomAccessRepositoryImpl(datasource);
  });

  test('setJoinRule_always_delegatesToTheDatasource', () async {
    // Act
    await repository.setJoinRule(roomId, JoinRuleChoice.knock);

    // Assert
    verify(datasource.setJoinRule(roomId, JoinRuleChoice.knock)).called(1);
  });

  test('setListed_always_delegatesToTheDatasource', () async {
    // Act
    await repository.setListed(roomId, isListed: false);

    // Assert
    verify(datasource.setListed(roomId, isListed: false)).called(1);
  });

  test('isEncrypted_always_readsTheDatasource', () {
    // Arrange
    when(datasource.isEncrypted(roomId)).thenReturn(true);

    // Act
    final isEncrypted = repository.isEncrypted(roomId);

    // Assert
    expect(isEncrypted, isTrue);
  });
}
