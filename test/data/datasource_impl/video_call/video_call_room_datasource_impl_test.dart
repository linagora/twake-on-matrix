import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/video_call/video_call_room_datasource_impl.dart';
import 'package:twake_chat/data/model/video_call/create_video_call_room_response.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/data/network/video_call/video_call_api.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';

import 'video_call_room_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<DioClient>()])
void main() {
  late MockDioClient mockDioClient;
  late DynamicUrlInterceptors tomServerUrlInterceptor;
  late VideoCallRoomDatasourceImpl datasource;

  const createRoomPath = '/_twake/v1/video_call/rooms';
  const testRoomUrl = 'https://meet.example.com/abc-defg-hij';

  PostExpectation<Future<dynamic>> whenCreateRoom() => when(
    mockDioClient.postToGetBody(
      any,
      data: anyNamed('data'),
      cancelToken: anyNamed('cancelToken'),
    ),
  );

  DioException badResponse(int statusCode, {Object? data}) {
    final requestOptions = RequestOptions(path: createRoomPath);
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  setUp(() {
    mockDioClient = MockDioClient();
    tomServerUrlInterceptor = DynamicUrlInterceptors()
      ..changeBaseUrl('https://tom.example.com/');
    datasource = VideoCallRoomDatasourceImpl(
      videoCallApi: VideoCallApi(mockDioClient),
      tomServerUrlInterceptor: tomServerUrlInterceptor,
    );
  });

  group('VideoCallRoomDatasourceImpl.createRoom', () {
    test('createRoom_whenRoomIsCreated_returnsTheResponse', () async {
      // Arrange
      whenCreateRoom().thenAnswer((_) async => {'url': testRoomUrl});

      // Act
      final response = await datasource.createRoom();

      // Assert
      expect(
        response,
        equals(const CreateVideoCallRoomResponse(url: testRoomUrl)),
      );
      verify(
        mockDioClient.postToGetBody(
          createRoomPath,
          data: <String, dynamic>{},
          cancelToken: anyNamed('cancelToken'),
        ),
      ).called(1);
    });

    test(
      'createRoom_whenToMIsNotConfigured_throwsUnavailableWithoutAnyRequest',
      () async {
        // Arrange
        tomServerUrlInterceptor.changeBaseUrl(null);

        // Act
        final creation = datasource.createRoom();

        // Assert
        await expectLater(
          creation,
          throwsA(isA<VideoCallRoomCreationUnavailableException>()),
        );
        verifyNever(
          mockDioClient.postToGetBody(
            any,
            data: anyNamed('data'),
            cancelToken: anyNamed('cancelToken'),
          ),
        );
      },
    );

    test('createRoom_whenToMAnswers404_throwsUnavailable', () async {
      // Arrange
      whenCreateRoom().thenThrow(
        badResponse(404, data: '<html>Cannot POST $createRoomPath</html>'),
      );

      // Act
      final creation = datasource.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationUnavailableException>()),
      );
    });

    test('createRoom_whenToMAnswers422_throwsUnavailable', () async {
      // Arrange
      whenCreateRoom().thenThrow(
        badResponse(422, data: {'errcode': 'M_UNPROCESSABLE'}),
      );

      // Act
      final creation = datasource.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationUnavailableException>()),
      );
    });

    for (final statusCode in [401, 500, 502]) {
      test(
        'createRoom_whenToMAnswers${statusCode}_throwsCreationFailed',
        () async {
          // Arrange
          final serverError = badResponse(
            statusCode,
            data: {'errcode': 'M_UNKNOWN', 'error': 'Refused'},
          );
          whenCreateRoom().thenThrow(serverError);

          // Act
          final creation = datasource.createRoom();

          // Assert
          await expectLater(
            creation,
            throwsA(
              isA<VideoCallRoomCreationFailedException>().having(
                (exception) => exception.cause,
                'cause',
                same(serverError),
              ),
            ),
          );
        },
      );
    }

    test('createRoom_whenToMIsUnreachable_throwsCreationFailed', () async {
      // Arrange
      whenCreateRoom().thenThrow(
        DioException(
          requestOptions: RequestOptions(path: createRoomPath),
          type: DioExceptionType.connectionError,
        ),
      );

      // Act
      final creation = datasource.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationFailedException>()),
      );
    });

    test('createRoom_whenResponseIsNotJson_throwsCreationFailed', () async {
      // Arrange
      whenCreateRoom().thenAnswer((_) async => '<html></html>');

      // Act
      final creation = datasource.createRoom();

      // Assert
      await expectLater(
        creation,
        throwsA(isA<VideoCallRoomCreationFailedException>()),
      );
    });

    testWidgets(
      'createRoom_whenToMDoesNotAnswerInTime_cancelsTheRequestAndThrowsCreationFailed',
      (tester) async {
        // Arrange
        CancelToken? cancelToken;
        whenCreateRoom().thenAnswer((invocation) {
          cancelToken = invocation.namedArguments[#cancelToken] as CancelToken?;
          return Completer<dynamic>().future;
        });
        Object? error;

        // Act
        unawaited(
          datasource.createRoom().then<void>(
            (_) {},
            onError: (Object exception) => error = exception,
          ),
        );
        await tester.pump(const Duration(seconds: 19));
        final errorBeforeTimeout = error;
        await tester.pump(const Duration(seconds: 1));

        // Assert
        expect(errorBeforeTimeout, isNull);
        expect(cancelToken?.isCancelled, isTrue);
        expect(
          error,
          isA<VideoCallRoomCreationFailedException>().having(
            (exception) => exception.cause,
            'cause',
            isA<TimeoutException>(),
          ),
        );
      },
    );
  });
}
