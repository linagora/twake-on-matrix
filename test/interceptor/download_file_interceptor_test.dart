import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:fluffychat/data/network/interceptor/download_file_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:matrix/matrix.dart';

import 'download_file_interceptor_test.mocks.dart';

@GenerateMocks(
  [
    Dio,
    Logs,
    RequestInterceptorHandler,
    ErrorInterceptorHandler,
    ResponseInterceptorHandler,
  ],
)
void main() {
  group('DownloadFileInterceptor', () {
    late DownloadFileInterceptor interceptor;

    setUp(() {
      interceptor = DownloadFileInterceptor();
    });

    const downloadPath =
        'https://matrix.linagora.com/_matrix/media/v3/download/';
    const uploadPath = 'https://matrix.linagora.com/_matrix/media/v3/upload/';

    test("""WHEN there are no request match the download path,
        THEN interceptor should not handle the request, the next interceptor will handle it""",
        () async {
      final options = RequestOptions(
        path: '${uploadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);

      verifyNever(mockHandler.reject(any));
      verify(mockHandler.next(options));

      expect(
        interceptor.currentDownloads.length,
        0,
      );
    });

    test("""WHEN there are one item in currentDownloads set,
        THEN another request comes with different path,
        THEN interceptor should put both requests in currentDownloads set""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/ADeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);

      verifyNever(mockHandler.reject(any));
      verify(mockHandler.next(options));
      verify(mockHandler.next(options1));
      expect(
        interceptor.currentDownloads.length,
        2,
      );
    });

    test("""WHEN there are two item in currentDownloads set,
        THEN another request comes with different path,
        THEN interceptor should have 3 requests in currentDownloads set""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/ADeVrZRwVXanSwyMMoxuKVmE',
      );
      final option2 = RequestOptions(
        path: '${downloadPath}linagora.com/MDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);
      interceptor.onRequest(option2, mockHandler);

      verifyNever(mockHandler.reject(any));
      verify(mockHandler.next(options));
      verify(mockHandler.next(options1));
      verify(mockHandler.next(option2));
      expect(
        interceptor.currentDownloads.length,
        3,
      );
    });

    test("""WHEN there are two item in currentDownloads set,
        THEN another request comes with upload path,
        THEN interceptor should have 2 requests in currentDownloads set""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/ADeVrZRwVXanSwyMMoxuKVmE',
      );
      final option2 = RequestOptions(
        path: '${uploadPath}linagora.com/MDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);
      interceptor.onRequest(option2, mockHandler);

      verifyNever(mockHandler.reject(any));
      verify(mockHandler.next(options));
      verify(mockHandler.next(options1));
      verify(mockHandler.next(option2));
      expect(
        interceptor.currentDownloads.length,
        2,
      );
    });

    test("""WHEN there are two item in currentDownloads set,
        THEN another request comes with different path,
        THEN interceptor should have 3 requests in currentDownloads set""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/ADeVrZRwVXanSwyMMoxuKVmE',
      );
      final option2 = RequestOptions(
        path: '${downloadPath}linagora.com/MDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);
      interceptor.onRequest(option2, mockHandler);

      verifyNever(mockHandler.reject(any));
      verify(mockHandler.next(options));
      verify(mockHandler.next(options1));
      verify(mockHandler.next(option2));
      expect(
        interceptor.currentDownloads.length,
        3,
      );
    });

    test("""WHEN there are two item in currentDownloads set,
        THEN another request comes with same path in currentDownloads set,
        THEN interceptor should have 2 requests in currentDownloads set""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/ADeVrZRwVXanSwyMMoxuKVmE',
      );
      final option2 = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);

      verify(mockHandler.next(options));
      verify(mockHandler.next(options1));
      try {
        interceptor.onRequest(option2, mockHandler);
      } on DioDuplicateDownloadException {
        // Expected exception thrown
      } catch (e) {
        expect(e, isA<DioDuplicateDownloadException>());
      }
      expect(
        interceptor.currentDownloads.length,
        2,
      );
    });

    test("""WHEN there are another request with same duplicate request path,
            THEN rejects duplicate download requests with exception""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);

      interceptor.onRequest(options, mockHandler);

      verify(
        mockHandler
            .reject(DioDuplicateDownloadException(requestOptions: options)),
      );
      expect(
        interceptor.currentDownloads.length,
        1,
      );
    });

    test("""WHEN add a duplicate request path:
            THEN throws DioDuplicateRequestException for duplicate downloads""",
        () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);

      try {
        interceptor.onRequest(options, mockHandler);
      } on DioDuplicateDownloadException {
        // Expected exception thrown
      } catch (e) {
        expect(e, isA<DioDuplicateDownloadException>());
      }
      expect(
        interceptor.currentDownloads.length,
        1,
      );
    });

    test("""WHEN allows new multiple download requests
            THEN allows all new multiple download requests""", () async {
      final options = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final options1 = RequestOptions(
        path: '${downloadPath}linagora.com/aDeVrRRwVXanSwyMMoxuKVmE',
      );
      final mockHandler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, mockHandler);
      interceptor.onRequest(options1, mockHandler);

      verifyNever(mockHandler.reject(any));
      expect(interceptor.currentDownloads.contains(options.path), true);
      expect(interceptor.currentDownloads.contains(options1.path), true);
      expect(interceptor.currentDownloads.length, 2);
    });

    test("""WHEN there is an error in downloading
          THEN removes element in currentDownloads on error""", () async {
      final requestOptions = RequestOptions(
        path: '${downloadPath}linagora.com/dDeVrZRwVXanSwyMMoxuKVmE',
      );
      final mockErr = DioException(requestOptions: requestOptions);
      final mockHandler = MockErrorInterceptorHandler();

      interceptor.onRequest(requestOptions, MockRequestInterceptorHandler());

      interceptor.onError(mockErr, mockHandler);

      expect(interceptor.currentDownloads.contains(requestOptions.path), false);
      expect(
        interceptor.currentDownloads.length,
        0,
      );
    });

    test("""WHEN there are successfully download requests
            THEN removes download in currentDownloads on successful response""",
        () async {
      final requestOptions = RequestOptions(path: '${downloadPath}success.mp3');
      final mockResponse = Response(requestOptions: requestOptions);
      final mockHandler = MockResponseInterceptorHandler();

      // Simulate download in progress
      interceptor.onRequest(requestOptions, MockRequestInterceptorHandler());

      interceptor.onResponse(mockResponse, mockHandler);

      expect(interceptor.currentDownloads.contains(requestOptions.path), false);
      expect(
        interceptor.currentDownloads.length,
        0,
      );
    });
  });
}
