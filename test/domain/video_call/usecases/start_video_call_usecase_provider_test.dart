import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.provider.dart';
import 'package:twake_chat/di/global/get_it_provider.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.provider.dart';

import 'start_video_call_usecase_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DioClient>(),
  MockSpec<Client>(),
  MockSpec<Room>(),
])
void main() {
  const testRoomId = '!room:example.com';
  const baseUrl = 'https://meet.example.com';

  test(
    'startVideoCallUseCase_always_createsTheRoomOnToMAndSendsWithTheGivenClient',
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
      when(mockRoom.membership).thenReturn(Membership.join);
      when(mockClient.getRoomById(testRoomId)).thenReturn(mockRoom);

      final getIt = GetIt.asNewInstance()
        ..registerSingleton<DioClient>(
          mockDioClient,
          instanceName: NetworkDI.tomDioClientName,
        );

      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          getItProvider.overrideWithValue(getIt),
          tomServerUrlInterceptorProvider.overrideWithValue(
            DynamicUrlInterceptors()..changeBaseUrl('https://tom.example.com/'),
          ),
        ],
      );

      // Act
      await container
          .read(startVideoCallUseCaseProvider(mockClient))
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
