import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/presentation/extensions/send_file_fake_event_extension.dart';

import '../../lenient_database.dart';

void main() {
  late Room room;

  setUpAll(() async => room = await getLenientRoom('!fake:example.com'));

  Map<String, Object?> contentOf(SyncUpdate update) =>
      update.rooms!.join!.values.first.timeline!.events!.first.content;

  test('the placeholder carries the batch key and the caption, so the album '
      'groups while it is still uploading', () async {
    final update = await room.sendFakeFileInfoEvent(
      FileInfo('a.png', bytes: Uint8List.fromList([1])),
      txid: 'Twake-1-1794209038793',
      captionInfo: 'hello',
      extraContent: {'app.twake.chat.batch': 'b1'},
    );

    final content = contentOf(update);
    expect(content['app.twake.chat.batch'], 'b1');
    expect(content['body'], 'hello');
    expect(content['filename'], 'a.png');
  });

  test('a placeholder without extra content has no batch key', () async {
    final update = await room.sendFakeFileInfoEvent(
      FileInfo('a.png', bytes: Uint8List.fromList([1])),
      txid: 'Twake-2-1794209038800',
    );

    expect(contentOf(update).containsKey('app.twake.chat.batch'), isFalse);
  });
}
