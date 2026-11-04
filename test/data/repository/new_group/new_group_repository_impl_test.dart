import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource/new_group/new_group_datasource.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository_impl.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';

import 'new_group_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NewGroupDatasource>()])
void main() {
  const request = CreateNewGroupChatRequest(groupName: 'Team');

  late MockNewGroupDatasource mockDatasource;
  late NewGroupRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockNewGroupDatasource();
    repository = NewGroupRepositoryImpl(mockDatasource);
  });

  test('createGroup_always_returnsTheDatasourceRoomId', () async {
    // Arrange
    when(mockDatasource.createGroup(request)).thenAnswer((_) async => '!r:x');

    // Act
    final roomId = await repository.createGroup(request);

    // Assert
    expect(roomId, '!r:x');
  });

  test('inviteUser_always_delegatesToTheDatasource', () async {
    // Act
    await repository.inviteUser(roomId: '!r:x', userId: '@a:x');

    // Assert
    verify(mockDatasource.inviteUser(roomId: '!r:x', userId: '@a:x')).called(1);
  });
}
