import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/clipboard.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../fake_client.dart';

class _RecordingClipboard extends Fake implements TwakeClipboard {
  Uint8List? mediaBytes;
  String? mediaMimeType;
  String? text;

  @override
  Future<void> copyMediaAsBytes(Uint8List data, {String? mimeType}) async {
    mediaBytes = data;
    mediaMimeType = mimeType;
  }

  @override
  Future<void> copyText(String text) async => this.text = text;
}

void main() {
  late Room room;
  late Timeline timeline;
  late _RecordingClipboard clipboard;

  setUpAll(() async {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
    final client = await getClient();
    room = Room(id: '!room:example.org', client: client);
    timeline = Timeline(
      room: room,
      chunk: TimelineChunk(events: []),
    );
  });

  setUp(() => clipboard = _RecordingClipboard());

  Event buildEvent(Map<String, dynamic> content, String eventId) => Event(
    content: content,
    type: EventTypes.Message,
    eventId: eventId,
    senderId: '@bob:example.org',
    originServerTs: DateTime(2026, 11, 10),
    room: room,
  );

  Future<void> copy(WidgetTester tester, Event event) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  event.copy(context, timeline, clipboard: clipboard),
              child: const Text('copy'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('copy'));
    await tester.pumpAndSettle();
  }

  testWidgets('copies the image itself, not its description', (tester) async {
    const eventId = r'$image:example.org';
    final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    room.sendingFilePlaceholders[eventId] = MatrixImageFile(
      bytes: bytes,
      name: 'orange.png',
      mimeType: 'image/png',
    );
    final event = buildEvent({
      'msgtype': MessageTypes.Image,
      'body': 'orange.png',
      'url': 'mxc://example.org/orange',
      'info': {'mimetype': 'image/png'},
    }, eventId);

    await copy(tester, event);

    expect(clipboard.mediaBytes, bytes);
    expect(clipboard.mediaMimeType, 'image/png');
    expect(clipboard.text, isNull);
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('copies the video itself, not its description', (tester) async {
    const eventId = r'$video:example.org';
    final bytes = Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
    room.sendingFilePlaceholders[eventId] = MatrixVideoFile(
      bytes: bytes,
      name: 'clip.mp4',
      mimeType: 'video/mp4',
    );
    final event = buildEvent({
      'msgtype': MessageTypes.Video,
      'body': 'clip.mp4',
      'url': 'mxc://example.org/clip',
      'info': {'mimetype': 'video/mp4'},
    }, eventId);

    await copy(tester, event);

    expect(clipboard.mediaBytes, bytes);
    expect(clipboard.mediaMimeType, 'video/mp4');
    expect(clipboard.text, isNull);
  });

  testWidgets('falls back to the text for a format the clipboard cannot hold', (
    tester,
  ) async {
    const eventId = r'$webm:example.org';
    room.sendingFilePlaceholders[eventId] = MatrixVideoFile(
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'clip.webm',
      mimeType: 'video/webm',
    );
    final event = buildEvent({
      'msgtype': MessageTypes.Video,
      'body': 'clip.webm',
      'url': 'mxc://example.org/webm',
      'info': {'mimetype': 'video/webm'},
    }, eventId);

    await copy(tester, event);

    expect(clipboard.mediaBytes, isNull);
    expect(clipboard.text, isNotNull);
  });

  testWidgets('copies the body of a text message', (tester) async {
    final event = buildEvent({
      'msgtype': MessageTypes.Text,
      'body': 'Hello there',
    }, r'$text:example.org');

    await copy(tester, event);

    expect(clipboard.text, 'Hello there');
    expect(clipboard.mediaBytes, isNull);
    expect(find.text('Text copied to clipboard'), findsOneWidget);
  });
}
