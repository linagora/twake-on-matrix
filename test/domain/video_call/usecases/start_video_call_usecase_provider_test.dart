import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/di/global/get_it_provider.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/pages/chat/providers/video_call_providers.dart';

import 'video_call_providers_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DioClient>(),
  MockSpec<Client>(),
  MockSpec<Room>(),
])
void main() {
  const testRoomId = '!room:example.com';
  const baseUrl = 'https://meet.example.com';

  test(
    'startVideoCallInteractor_always_createsTheRoomOnToMAndSendsWithTheGivenClient',
    () async {
      // Arrange
      final mockDioClient = MockDioClient();
      when(
        mockDioClient.postToGetBody(
          any,
          data: anyNamed('data'),
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => {'url': '$baseUrl/abc-defg-hij'});

      final mockRoom = MockRoom();
      final mockClient = MockClient();
      when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

      final getIt = GetIt.asNewInstance()
        ..registerSingleton<DioClient>(
          mockDioClient,
          instanceName: NetworkDI.tomDioClientName,
        )
        ..registerSingleton<DynamicUrlInterceptors>(
          DynamicUrlInterceptors()..changeBaseUrl('https://tom.example.com/'),
          instanceName: NetworkDI.tomServerUrlInterceptorName,
        );

      final container = ProviderContainer(
        overrides: [getItProvider.overrideWithValue(getIt)],
      );
      addTearDown(container.dispose);

      // Act
      await container
          .read(startVideoCallInteractorProvider(mockClient))
          .execute(
            roomId: testRoomId,
            baseUrl: baseUrl,
            startedTitle: 'Has started a video call',
          );

      // Assert
      verify(
        mockDioClient.postToGetBody(
          '/_twake/v1/video_call/rooms',
          data: anyNamed('data'),
          cancelToken: anyNamed('cancelToken'),
        ),
      ).called(1);
      verify(
        mockRoom.sendEvent({
          'msgtype': MessageTypes.Text,
          'body': 'Has started a video call $baseUrl/abc-defg-hij',
          'call_url': '$baseUrl/abc-defg-hij',
        }),
      ).called(1);
    },
  );
}
