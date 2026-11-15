import 'dart:io';

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
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';
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
late Directory _tempDir;

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  setUpAll(_setUpRoom);
  setUp(_setUpClipboardAndStorage);
  tearDown(_tearDownStorage);

  testWidgets(
    'copies the image itself, not its description',
    _copiesMedia(
      MatrixImageFile(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]),
        name: 'orange.png',
        mimeType: 'image/png',
      ),
    ),
  );
  testWidgets(
    'copies the video itself, not its description',
    _copiesMedia(
      MatrixVideoFile(
        bytes: Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]),
        name: 'clip.mp4',
        mimeType: 'video/mp4',
      ),
    ),
  );
  testWidgets(
    'falls back to the text for a format the clipboard cannot hold',
    _fallsBackToTextForUnknownFormat,
  );
  testWidgets('copies the body of a text message', _copiesText);
  testWidgets(
    'copies a received file already on the device',
    _copiesReceivedFileFromDisk,
  );
  testWidgets(
    'shows an error when a received file cannot be downloaded',
    _showsErrorWhenDownloadFails,
  );
  testWidgets(
    'copies the text of a received WebM without downloading it',
    _copiesTextOfReceivedWebmWithoutDownload,
  );
  testWidgets(
    'copies the text of a video over 100 MB without downloading it',
    _copiesTextOfLargeVideoWithoutDownload,
  );
  testWidgets(
    'copies the text when the file on the device is over 100 MB',
    _copiesTextOfLargeFileWithoutKnownSize,
  );
  testWidgets(
    'never copies a file that could not be decrypted',
    _failsWhenDecryptionFails,
  );
}

void _setUpClipboardAndStorage() {
  _clipboard = _RecordingClipboard();
  _tempDir = Directory.systemTemp.createTempSync('event_copy_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        _pathProviderChannel,
        (_) async => _tempDir.path,
      );
}

void _tearDownStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, null);
  _tempDir.deleteSync(recursive: true);
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

Event _buildEvent(Map<String, dynamic> content) => Event(
  content: content,
  type: EventTypes.Message,
  eventId: '\$${content['body']}:example.org',
  senderId: '@bob:example.org',
  originServerTs: DateTime(2026, 11, 10),
  room: _room,
);

Event _mediaEvent(MatrixFile file) {
  final event = _buildEvent({
    'msgtype': file is MatrixImageFile
        ? MessageTypes.Image
        : MessageTypes.Video,
    'body': file.name,
    'url': 'mxc://example.org/${file.name}',
    'info': {'mimetype': file.mimeType},
  });
  _room.sendingFilePlaceholders[event.eventId] = file;
  return event;
}

Future<void> _copy(WidgetTester tester, Event event) async {
  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: Scaffold(body: SizedBox()),
    ),
  );
  final context = tester.element(find.byType(SizedBox));
  await tester.runAsync(
    () => event.copy(context, _timeline, clipboard: _clipboard),
  );
  await tester.pumpAndSettle();
}

WidgetTesterCallback _copiesMedia(MatrixFile file) => (tester) async {
  final event = _mediaEvent(file);

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, file.bytes);
  expect(_clipboard.mediaMimeType, file.mimeType);
  expect(_clipboard.text, isNull);
  expect(find.text('Copied to clipboard'), findsOneWidget);
};

Future<void> _fallsBackToTextForUnknownFormat(WidgetTester tester) async {
  final event = _mediaEvent(
    MatrixVideoFile(
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
  });

  await _copy(tester, event);

  expect(_clipboard.text, 'Hello there');
  expect(_clipboard.mediaBytes, isNull);
  expect(find.text('Text copied to clipboard'), findsOneWidget);
}

Event _receivedEvent(
  String name,
  String mimeType,
  int? size, {
  Map<String, dynamic>? file,
}) => _buildEvent({
  'msgtype': MessageTypes.Video,
  'body': name,
  if (file == null) 'url': 'mxc://example.org/$name',
  if (file != null) 'file': file,
  'info': {'mimetype': mimeType, 'size': ?size},
});

Future<void> _writeDownloadedFile(
  WidgetTester tester,
  Event event,
  void Function(File file) write,
) => tester.runAsync(() async {
  final path = await StorageDirectoryManager.instance.getFilePathInAppDownloads(
    eventId: event.eventId,
    fileName: event.body,
  );
  final file = File(path)..createSync(recursive: true);
  write(file);
});

Future<void> _copiesReceivedFileFromDisk(WidgetTester tester) async {
  final bytes = Uint8List.fromList([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
  final event = _receivedEvent('received.mp4', 'video/mp4', bytes.length);
  await _writeDownloadedFile(
    tester,
    event,
    (file) => file.writeAsBytesSync(bytes),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, bytes);
  expect(_clipboard.mediaMimeType, 'video/mp4');
  expect(find.text('Copied to clipboard'), findsOneWidget);
}

Future<void> _showsErrorWhenDownloadFails(WidgetTester tester) async {
  final event = _receivedEvent('missing.png', 'image/png', 3);

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(_clipboard.text, isNull);
  expect(find.text('Copy image failed'), findsOneWidget);
}

Future<void> _copiesTextOfReceivedWebmWithoutDownload(
  WidgetTester tester,
) async {
  final event = _receivedEvent('received.webm', 'video/webm', 3);

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(_clipboard.text, isNotNull);
  expect(find.text('Copy image failed'), findsNothing);
}

Future<void> _copiesTextOfLargeVideoWithoutDownload(WidgetTester tester) async {
  final event = _receivedEvent('large.mp4', 'video/mp4', 101 * 1024 * 1024);

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(_clipboard.text, isNotNull);
  expect(find.text('Copy image failed'), findsNothing);
}

Future<void> _copiesTextOfLargeFileWithoutKnownSize(WidgetTester tester) async {
  final event = _receivedEvent('nosize.mp4', 'video/mp4', null);
  await _writeDownloadedFile(
    tester,
    event,
    (file) => file.openSync(mode: FileMode.write)
      ..truncateSync(101 * 1024 * 1024)
      ..closeSync(),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(_clipboard.text, isNotNull);
}

Future<void> _failsWhenDecryptionFails(WidgetTester tester) async {
  final event = _receivedEvent(
    'secret.png',
    'image/png',
    null,
    file: {
      'url': 'mxc://example.org/secret',
      'v': 'v2',
      'iv': 'AAAAAAAAAAAAAAAAAAAAAA',
      'hashes': {'sha256': 'not-the-hash'},
      'key': {
        'kty': 'oct',
        'alg': 'A256CTR',
        'ext': true,
        'key_ops': ['encrypt', 'decrypt'],
        'k': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      },
    },
  );
  await _writeDownloadedFile(
    tester,
    event,
    (file) => file.writeAsBytesSync([1, 2, 3, 4]),
  );

  await _copy(tester, event);

  expect(_clipboard.mediaBytes, isNull);
  expect(find.text('Copy image failed'), findsOneWidget);
}
