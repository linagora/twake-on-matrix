import 'dart:convert';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/images_builder/sending_image_info_widget.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../../../fake_client.dart';

class _FakeUploadManager implements UploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = await getClient();

  setUp(() {
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('expands a narrow sending image to the long caption bubble width', (
    tester,
  ) async {
    final event = Event(
      content: {
        'body':
            'A deliberately long caption that needs a readable bubble width.',
        'filename': 'portrait.png',
        'info': {'h': 1600, 'mimetype': 'image/png', 'size': 68, 'w': 400},
        'msgtype': 'm.image',
        'url': 'mxc://example.org/portrait',
      },
      type: EventTypes.Message,
      eventId: '\$portrait:example.org',
      senderId: '@alice:example.org',
      originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
      room: Room(id: '!room:example.org', client: client),
    );
    final matrixFile = MatrixImageFile(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      name: 'portrait.png',
      mimeType: 'image/png',
      width: 400,
      height: 1600,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SendingImageInfoWidget(
            matrixFile: matrixFile,
            event: event,
            displayImageInfo: DisplayImageInfo(
              size: const Size(85, 340),
              hasBlur: true,
            ),
            bubbleWidth: 300,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(SendingImageInfoWidget)).width, 300);
    expect(tester.takeException(), isNull);
  });
}
