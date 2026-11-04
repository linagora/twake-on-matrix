import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource/forward/forward_datasource.dart';
import 'package:twake_chat/data/repository/forward/forward_repository_impl.dart';

import 'forward_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ForwardDatasource>()])
void main() {
  const roomId = '!a:example.com';
  const content = {'msgtype': 'm.text', 'body': 'hello'};

  late MockForwardDatasource mockDatasource;
  late ForwardRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockForwardDatasource();
    repository = ForwardRepositoryImpl(mockDatasource);
  });

  test('isJoined_always_returnsTheDatasourceAnswer', () {
    // Arrange
    when(mockDatasource.isJoined(roomId)).thenReturn(true);

    // Act
    final joined = repository.isJoined(roomId);

    // Assert
    expect(joined, isTrue);
  });

  test('sendMessage_always_delegatesToTheDatasource', () async {
    // Act
    await repository.sendMessage(roomId: roomId, content: content);

    // Assert
    verify(
      mockDatasource.sendMessage(roomId: roomId, content: content),
    ).called(1);
  });
}
