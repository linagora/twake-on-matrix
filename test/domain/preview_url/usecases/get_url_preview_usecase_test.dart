import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/preview_url/exceptions/get_url_preview_exception.dart';
import 'package:twake_chat/domain/preview_url/usecases/get_url_preview_usecase.dart';

import '../fake_media_repository.dart';

void main() {
  final uri = Uri.parse('https://example.com');

  group('GetUrlPreviewUseCase', () {
    test('returns the preview of the repository', () async {
      final preview = UrlPreview(title: 'Example', description: 'Desc');
      final repository = FakeMediaRepository(
        onGetUrlPreview: (_) async => preview,
      );

      final result = await GetUrlPreviewUseCase(
        repository,
      ).execute(uri: uri, preferredPreviewTime: 2000);

      expect(result, preview);
      expect(repository.calls.single.uri, uri);
      expect(repository.calls.single.preferredPreviewTime, 2000);
    });

    test('passes a null preferred preview time through', () async {
      final repository = FakeMediaRepository();

      await GetUrlPreviewUseCase(repository).execute(uri: uri);

      expect(repository.calls.single.preferredPreviewTime, isNull);
    });

    test('wraps a repository error in GetUrlPreviewException', () async {
      final cause = Exception('network');
      final repository = FakeMediaRepository(
        onGetUrlPreview: (_) async => throw cause,
      );

      await expectLater(
        GetUrlPreviewUseCase(repository).execute(uri: uri),
        throwsA(
          isA<GetUrlPreviewException>().having((e) => e.cause, 'cause', cause),
        ),
      );
    });

    test('keeps the stack trace of the repository error', () async {
      final repository = FakeMediaRepository(
        onGetUrlPreview: (_) => Future.error(StateError('boom')),
      );

      try {
        await GetUrlPreviewUseCase(repository).execute(uri: uri);
        fail('should throw');
      } on GetUrlPreviewException catch (e, s) {
        expect(e.cause, isA<StateError>());
        expect(s, isNotNull);
        expect(e.toString(), contains('GetUrlPreviewException'));
      }
    });
  });
}
