import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';

import 'new_feed_providers_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
void main() {
  const testRoomId = '!feed:example.com';

  test(
    'createNewFeedInteractor_always_createsTheFeedWithTheGivenClient',
    () async {
      // Arrange
      final mockClient = MockClient();
      when(
        mockClient.request(
          any,
          any,
          data: anyNamed('data'),
          contentType: anyNamed('contentType'),
          query: anyNamed('query'),
        ),
      ).thenAnswer((_) async => {'room_id': testRoomId});
      when(mockClient.getRoomById(testRoomId)).thenReturn(MockRoom());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final roomId = await container
          .read(createNewFeedInteractorProvider(mockClient))
          .execute(feedName: 'My feed');

      // Assert
      expect(roomId, equals(testRoomId));
      verify(
        mockClient.request(
          RequestType.POST,
          '/client/v3/createRoom',
          data: anyNamed('data'),
          contentType: anyNamed('contentType'),
          query: anyNamed('query'),
        ),
      ).called(1);
    },
  );
}
