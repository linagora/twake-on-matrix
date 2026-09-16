import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/repository/feed/feed_repository.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';

import 'create_new_feed_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FeedRepository>()])
void main() {
  late MockFeedRepository mockFeedRepository;
  late CreateNewFeedInteractor interactor;

  setUp(() {
    mockFeedRepository = MockFeedRepository();
    interactor = CreateNewFeedInteractor(mockFeedRepository);
  });

  group('CreateNewFeedInteractor', () {
    test('execute_whenFeedIsCreated_returnsItsRoomId', () async {
      // Arrange
      when(
        mockFeedRepository.createFeed(
          name: 'My feed',
          avatarUrl: 'mxc://example.com/avatar',
        ),
      ).thenAnswer((_) async => '!feed:example.com');

      // Act
      final roomId = await interactor.execute(
        feedName: 'My feed',
        avatarUrl: 'mxc://example.com/avatar',
      );

      // Assert
      expect(roomId, equals('!feed:example.com'));
    });

    test(
      'execute_whenHomeserverDoesNotSupportFeeds_throwsFeedNotSupported',
      () async {
        // Arrange
        when(
          mockFeedRepository.createFeed(
            name: anyNamed('name'),
            avatarUrl: anyNamed('avatarUrl'),
          ),
        ).thenAnswer(
          (_) => Future.error(const FeedNotSupportedByHomeserverException()),
        );

        // Act
        final creation = interactor.execute(feedName: 'My feed');

        // Assert
        await expectLater(
          creation,
          throwsA(isA<FeedNotSupportedByHomeserverException>()),
        );
      },
    );
  });
}
