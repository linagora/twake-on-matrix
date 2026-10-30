import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/media/media_repository.provider.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/preview_url/exceptions/get_url_preview_exception.dart';
import 'package:twake_chat/providers/url_preview_provider.dart';

import '../domain/preview_url/fake_media_repository.dart';

void main() {
  final uri = Uri.parse('https://example.com');
  late FakeMediaRepository repository;

  ProviderContainer createContainer() => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [mediaRepositoryProvider.overrideWithValue(repository)],
  );

  setUp(() => repository = FakeMediaRepository());

  group('urlPreviewProvider', () {
    test('starts loading, then holds the preview', () async {
      final completer = Completer<UrlPreview>();
      repository.onGetUrlPreview = (_) => completer.future;
      final container = createContainer();
      container.listen(urlPreviewProvider(uri), (_, _) {});

      expect(container.read(urlPreviewProvider(uri)), isA<AsyncLoading>());

      final preview = UrlPreview(title: 'Example');
      completer.complete(preview);
      await container.read(urlPreviewProvider(uri).future);

      expect(container.read(urlPreviewProvider(uri)).value, preview);
    });

    test('asks for the default preferred preview time', () async {
      final container = createContainer();

      await container.read(urlPreviewProvider(uri).future);

      expect(repository.calls.single.uri, uri);
      expect(
        repository.calls.single.preferredPreviewTime,
        defaultPreferredPreviewTimeInMilliseconds,
      );
      expect(defaultPreferredPreviewTimeInMilliseconds, 2000);
    });

    test('exposes a typed error and does not retry', () async {
      repository.onGetUrlPreview = (_) async => throw Exception('refused');
      final container = createContainer();
      container.listen(urlPreviewProvider(uri), (_, _) {});

      await expectLater(
        container.read(urlPreviewProvider(uri).future),
        throwsA(isA<GetUrlPreviewException>()),
      );

      final state = container.read(urlPreviewProvider(uri));
      expect(state, isA<AsyncError>());
      expect(state.value, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.calls, hasLength(1));
    });

    test('fetches once per link while listened', () async {
      final container = createContainer();
      container.listen(urlPreviewProvider(uri), (_, _) {});
      container.listen(urlPreviewProvider(uri), (_, _) {});

      await container.read(urlPreviewProvider(uri).future);

      expect(repository.calls, hasLength(1));
    });

    test('keeps a separate preview per link', () async {
      final other = Uri.parse('https://other.org');
      final container = createContainer();
      container.listen(urlPreviewProvider(uri), (_, _) {});
      container.listen(urlPreviewProvider(other), (_, _) {});

      final first = await container.read(urlPreviewProvider(uri).future);
      final second = await container.read(urlPreviewProvider(other).future);

      expect(first.title, 'example.com');
      expect(second.title, 'other.org');
      expect(repository.calls.map((c) => c.uri), [uri, other]);
    });

    test('fetches again once no widget listens any more', () async {
      final container = createContainer();
      final sub = container.listen(urlPreviewProvider(uri), (_, _) {});
      await container.read(urlPreviewProvider(uri).future);
      sub.close();
      await container.pump();

      container.listen(urlPreviewProvider(uri), (_, _) {});
      await container.read(urlPreviewProvider(uri).future);

      expect(repository.calls, hasLength(2));
    });
  });
}
