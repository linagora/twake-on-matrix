import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/repository/media/media_repository.provider.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/pages/chat_details/chat_details_page_view/links/chat_details_links_item.dart';

import '../../domain/preview_url/fake_media_repository.dart';

class _FakeRoom extends Fake implements Room {
  @override
  String get id => '!room:example.com';
}

void main() {
  const link = 'https://example.com';
  late FakeMediaRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMediaRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [mediaRepositoryProvider.overrideWithValue(repository)],
    );
  });

  final event = Event(
    content: {'body': 'see $link', 'msgtype': MessageTypes.Text},
    type: EventTypes.Message,
    eventId: r'$link',
    senderId: '@alice:example.com',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
    room: _FakeRoom(),
  );

  Future<void> pumpItem(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: ChatDetailsLinkItem(event: event)),
        ),
      ),
    );
    await tester.pump();
  }

  group('ChatDetailsLinkItem', () {
    testWidgets('shows the title and description of the preview', (
      tester,
    ) async {
      repository.onGetUrlPreview = (_) async =>
          UrlPreview(title: 'Example', description: 'An example page');

      await pumpItem(tester);

      expect(find.text('Example'), findsOneWidget);
      expect(find.text('An example page'), findsOneWidget);
      expect(find.text(link), findsOneWidget);
      expect(repository.calls.single.uri, Uri.parse(link));
    });

    testWidgets('keeps the link as title when the preview fails', (
      tester,
    ) async {
      repository.onGetUrlPreview = (_) async => throw Exception('refused');

      await pumpItem(tester);

      expect(find.text(link), findsNWidgets(2));
      expect(find.text('An example page'), findsNothing);
    });

    testWidgets('keeps the link as title while the preview loads', (
      tester,
    ) async {
      final completer = Completer<UrlPreview>();
      repository.onGetUrlPreview = (_) => completer.future;

      await pumpItem(tester);

      expect(find.text(link), findsNWidgets(2));

      completer.complete(UrlPreview(title: 'Example'));
      await tester.pumpAndSettle();

      expect(find.text('Example'), findsOneWidget);
    });
  });
}
