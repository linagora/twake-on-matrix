import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource/feed/feed_datasource.dart';
import 'package:twake_chat/data/repository/feed/feed_repository_impl.dart';

import 'feed_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FeedDatasource>()])
void main() {
  late MockFeedDatasource mockFeedDatasource;
  late FeedRepositoryImpl repository;

  setUp(() {
    mockFeedDatasource = MockFeedDatasource();
    repository = FeedRepositoryImpl(mockFeedDatasource);
  });

  group('FeedRepositoryImpl', () {
    test('createFeed_always_delegatesToTheDatasource', () async {
      // Arrange
      when(
        mockFeedDatasource.createFeed(
          name: 'My feed',
          avatarUrl: 'mxc://example.com/avatar',
        ),
      ).thenAnswer((_) async => '!feed:example.com');

      // Act
      final roomId = await repository.createFeed(
        name: 'My feed',
        avatarUrl: 'mxc://example.com/avatar',
      );

      // Assert
      expect(roomId, equals('!feed:example.com'));
    });
  });
}
