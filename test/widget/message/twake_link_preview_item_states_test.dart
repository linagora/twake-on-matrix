import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/data/repository/media/media_repository.provider.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';

import '../../domain/preview_url/fake_media_repository.dart';

void main() {
  late FakeMediaRepository repository;

  setUp(() => repository = FakeMediaRepository());

  Widget app(String? link) => ProviderScope(
    retry: (_, _) => null,
    overrides: [mediaRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      home: Scaffold(
        body: TwakeLinkPreviewItem(ownMessage: true, previewLink: link),
      ),
    ),
  );

  final body = find.byKey(TwakeLinkPreviewItem.linkPreviewBodyKey);
  // The skeleton is the only state that shows the title padding without
  // the preview body.
  final skeleton = find.byKey(LinkPreviewBuilder.paddingTitleKey);

  group('TwakeLinkPreviewItem states', () {
    testWidgets('shows the skeleton while the preview loads', (tester) async {
      final completer = Completer<UrlPreview>();
      repository.onGetUrlPreview = (_) => completer.future;

      await tester.pumpWidget(app('https://example.com'));

      expect(skeleton, findsWidgets);
      expect(body, findsNothing);

      completer.complete(UrlPreview(title: 'Example'));
      await tester.pump();

      expect(body, findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
    });

    testWidgets('shows nothing when the preview fails', (tester) async {
      repository.onGetUrlPreview = (_) async => throw Exception('refused');

      await tester.pumpWidget(app('https://example.com'));
      await tester.pump();

      expect(body, findsNothing);
      expect(skeleton, findsNothing);
      expect(repository.calls, hasLength(1));
    });

    for (final link in [null, '', '   ']) {
      testWidgets('shows the skeleton without a request for "$link"', (
        tester,
      ) async {
        await tester.pumpWidget(app(link));
        await tester.pump();

        expect(skeleton, findsWidgets);
        expect(body, findsNothing);
        expect(repository.calls, isEmpty);
      });
    }

    testWidgets('fetches the new link when it changes', (tester) async {
      await tester.pumpWidget(app('https://example.com'));
      await tester.pump();
      expect(find.text('example.com'), findsOneWidget);

      await tester.pumpWidget(app('https://other.org'));
      await tester.pump();

      expect(find.text('other.org'), findsOneWidget);
      expect(repository.calls.map((c) => c.uri.host), [
        'example.com',
        'other.org',
      ]);
    });

    testWidgets('sends the default preferred preview time', (tester) async {
      await tester.pumpWidget(app('https://example.com'));
      await tester.pump();

      expect(repository.calls.single.preferredPreviewTime, 2000);
    });
  });
}
