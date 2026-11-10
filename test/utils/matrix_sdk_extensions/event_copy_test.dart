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

late Room _room;
late Timeline _timeline;
late _RecordingClipboard _clipboard;

void main() {
  setUpAll(_setUpRoom);
  setUp(() => _clipboard = _RecordingClipboard());

  testWidgets('copies the image itself, not its description', _copiesImage);
  testWidgets('copies the video itself, not its description', _copiesVideo);
  testWidgets(
    'falls back to the text for a format the clipboard cannot hold',
    _fallsBackToTextForUnknownFormat,
  );
  testWidgets('copies the body of a text message', _copiesText);
}

Future<void> _setUpRoom() async {
  if (!getIt.isRegistered<ResponsiveUtils>()) {
    getIt.registerSingleton(ResponsiveUtils());
  }
  final client = await getClient();
  _room = Room(id: '!room:example.org', client: client);
  _timeline = Timeline(
    room: _room,
    chunk: TimelineChunk(events: []),
  );
}

Event _buildEvent(Map<String, dynamic> content, String eventId) => Event(
  content: content,
  type: EventTypes.Message,
  eventId: eventId,
  senderId: '@bob:example.org',
  originServerTs: DateTime(2026, 11, 10),
  room: _room,
);

Event _mediaEvent({
  required String eventId,
  required String msgtype,
  required MatrixFile file,
}) {
  _room.sendingFilePlaceholders[eventId] = file;
  return _buildEvent({
    'msgtype': msgtype,
    'body': file.name,
    'url': 'mxc://example.org/${file.name}',
    'info': {'mimetype': file.mimeType},
  }, eventId);
}

Future<void> _copy(WidgetTester tester, Event event) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                event.copy(context, _timeline, clipboard: _clipboard),
            child: const Text('copy'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('copy'));
  await tester.pumpAndSettle();
}

Future<void> _copiesImage(WidgetTester tester) async {
  final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
  final event = _mediaEvent(
    eventId: r'$image:example.org',
    msgtype: MessageTypes.Image,
    file: MatrixImageFile(
      bytes: bytes,
      name: 'orange.png',
      mimeType: 'image/png',
    ),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, bytes);
  expect(_clipboard.mediaMimeType, 'image/png');
  expect(_clipboard.text, isNull);
  expect(find.text('Copied to clipboard'), findsOneWidget);
}

Future<void> _copiesVideo(WidgetTester tester) async {
  final bytes = Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
  final event = _mediaEvent(
    eventId: r'$video:example.org',
    msgtype: MessageTypes.Video,
    file: MatrixVideoFile(
      bytes: bytes,
      name: 'clip.mp4',
      mimeType: 'video/mp4',
    ),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, bytes);
  expect(_clipboard.mediaMimeType, 'video/mp4');
  expect(_clipboard.text, isNull);
}

Future<void> _fallsBackToTextForUnknownFormat(WidgetTester tester) async {
  final event = _mediaEvent(
    eventId: r'$webm:example.org',
    msgtype: MessageTypes.Video,
    file: MatrixVideoFile(
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'clip.webm',
      mimeType: 'video/webm',
    ),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(_clipboard.text, isNotNull);
}

Future<void> _copiesText(WidgetTester tester) async {
  final event = _buildEvent({
    'msgtype': MessageTypes.Text,
    'body': 'Hello there',
  }, r'$text:example.org');

  await _copy(tester, event);

  expect(_clipboard.text, 'Hello there');
  expect(_clipboard.mediaBytes, isNull);
  expect(find.text('Text copied to clipboard'), findsOneWidget);
}
