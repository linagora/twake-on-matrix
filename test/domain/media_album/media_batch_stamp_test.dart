import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/media_album/policy/media_batch_stamp.dart';

void main() {
  const stamp = MediaBatchStamp();
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  group('MediaBatchStamp.newBatchIdFor', () {
    test('gives no id to a single file', () {
      expect(stamp.newBatchIdFor(1), isNull);
      expect(stamp.newBatchIdFor(0), isNull);
    });

    test('gives a UUID v4 to two or more files', () {
      expect(stamp.newBatchIdFor(2), matches(uuidV4));
      expect(stamp.newBatchIdFor(6), matches(uuidV4));
    });

    test('gives a different id to two sends', () {
      expect(stamp.newBatchIdFor(3), isNot(stamp.newBatchIdFor(3)));
    });
  });

  group('MediaBatchStamp.contentFor', () {
    test('writes the key shared with the web client', () {
      expect(MediaBatchStamp.contentKey, 'app.twake.chat.batch');
      expect(stamp.contentFor('abc'), {'app.twake.chat.batch': 'abc'});
    });

    test('writes nothing without an id', () {
      expect(stamp.contentFor(null), isNull);
      expect(stamp.contentFor(''), isNull);
    });
  });

  group('MediaBatchStamp.withoutBatch', () {
    test('drops the key and keeps the rest, without touching the input', () {
      final content = <String, Object?>{
        'msgtype': 'm.image',
        'app.twake.chat.batch': 'abc',
      };

      expect(stamp.withoutBatch(content), {'msgtype': 'm.image'});
      expect(content.containsKey('app.twake.chat.batch'), isTrue);
    });
  });

  group('MediaBatchStamp.restampForwarded', () {
    Map<String, Object?> image(String batch) => {
      'msgtype': 'm.image',
      'body': 'img',
      'app.twake.chat.batch': batch,
    };

    test('gives two forwarded images one fresh id', () {
      final result = stamp.restampForwarded([
        stamp.withoutBatch(image('old')),
        stamp.withoutBatch(image('old')),
      ]);

      final ids = result.map((c) => c['app.twake.chat.batch']).toSet();
      expect(ids, hasLength(1));
      expect(ids.single, matches(uuidV4));
    });

    test('forwarding the same album twice gives two different ids', () {
      final album = [
        stamp.withoutBatch(image('old')),
        stamp.withoutBatch(image('old')),
      ];

      final first = stamp.restampForwarded(album).first;
      final second = stamp.restampForwarded(album).first;

      expect(
        first['app.twake.chat.batch'],
        isNot(second['app.twake.chat.batch']),
      );
    });

    test('leaves one image and other messages without a key', () {
      final contents = [
        stamp.withoutBatch(image('old')),
        {'msgtype': 'm.text', 'body': 'hi'},
      ];

      expect(stamp.restampForwarded(contents), contents);
    });

    test('stamps only the images of a mixed selection', () {
      final result = stamp.restampForwarded([
        {'msgtype': 'm.image', 'body': 'a'},
        {'msgtype': 'm.file', 'body': 'f'},
        {'msgtype': 'm.image', 'body': 'b'},
      ], random: Random(1));

      expect(result[0]['app.twake.chat.batch'], isNotNull);
      expect(result[1].containsKey('app.twake.chat.batch'), isFalse);
      expect(
        result[0]['app.twake.chat.batch'],
        result[2]['app.twake.chat.batch'],
      );
    });
  });
}
