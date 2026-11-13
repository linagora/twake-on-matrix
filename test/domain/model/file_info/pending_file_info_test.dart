import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/domain/model/file_info/pending_file_info.dart';

/// A cancel that never comes.
final _never = Completer<void>().future;

PendingFileInfo _pending(
  Future<FileInfo> resolved, {
  Future<FileInfo> Function()? retry,
}) => PendingFileInfo('a.pdf', size: 1, resolved: resolved, retry: retry);

Future<FileInfo?> _wait(PendingFileInfo pending) =>
    pending.whenReady(cancelled: () => false, onCancelled: _never);

final _onDisk = FileInfo('a.pdf', filePath: '/tmp/a.pdf');

void main() {
  group('PendingFileInfo', () {
    test('announces the size it was given, with no file on disk', () {
      final pending = PendingFileInfo(
        'report.pdf',
        size: 2048,
        customMimeType: 'application/pdf',
        resolved: Future.value(FileInfo('report.pdf')),
      );

      expect(pending.fileSize, 2048);
      expect(pending.metadata, {'mimetype': 'application/pdf', 'size': 2048});
      expect(pending.filePath, isNull);
    });

    test('is a different file when the announced size differs', () {
      final resolved = Future.value(FileInfo('a'));

      expect(
        PendingFileInfo('a', size: 1, resolved: resolved),
        isNot(PendingFileInfo('a', size: 2, resolved: resolved)),
      );
    });

    test('hands over the file once it is on disk', () async {
      final saved = FileInfo('a.pdf', filePath: '/tmp/a.pdf');
      final pending = _pending(Future.value(saved));

      expect(await pending.resolved, same(saved));
    });
  });

  group('whenReady', () {
    test('a cancel frees the wait before the bytes arrive', () async {
      final bytes = Completer<FileInfo>();
      final cancel = Completer<void>();
      final pending = _pending(bytes.future);

      final ready = pending.whenReady(
        cancelled: () => cancel.isCompleted,
        onCancelled: cancel.future,
      );
      cancel.complete();

      expect(await ready, isNull);
      bytes.completeError(Exception('late'));
      await Future<void>.delayed(Duration.zero);
    });

    test('is the file once it is on disk', () async {
      final saved = FileInfo('a.pdf', filePath: '/tmp/a.pdf');
      final pending = _pending(Future.value(saved));

      expect(
        await pending.whenReady(cancelled: () => false, onCancelled: _never),
        same(saved),
      );
    });

    test(
      'is null when the user cancelled while the file was on its way',
      () async {
        final pending = _pending(
          Future.value(FileInfo('a.pdf', filePath: '/tmp/a.pdf')),
        );

        expect(
          await pending.whenReady(cancelled: () => true, onCancelled: _never),
          isNull,
        );
      },
    );

    test(
      'is null when the file never came and the user had cancelled',
      () async {
        final pending = _pending(
          Future<FileInfo>.error(Exception('not received')),
        );

        expect(
          await pending.whenReady(cancelled: () => true, onCancelled: _never),
          isNull,
        );
      },
    );

    test('fails when the file never came and nobody cancelled', () async {
      final pending = _pending(
        Future<FileInfo>.error(Exception('not received')),
      );

      await expectLater(
        pending.whenReady(cancelled: () => false, onCancelled: _never),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('retry', () {
    test(
      'the first wait uses resolved, a later one brings the file again',
      () async {
        var brought = 0;
        final pending = _pending(
          Future<FileInfo>.error(Exception('not received')),
          retry: () async {
            brought++;
            return _onDisk;
          },
        );

        await expectLater(_wait(pending), throwsA(isA<Exception>()));
        final again = await _wait(pending);

        expect(brought, 1);
        expect(again?.filePath, '/tmp/a.pdf');
      },
    );

    test('a retry that fails again fails the wait', () async {
      final pending = _pending(
        Future<FileInfo>.error(Exception('first')),
        retry: () => Future<FileInfo>.error(Exception('second')),
      );
      await _wait(pending).then<void>((_) {}, onError: (_) {});

      await expectLater(_wait(pending), throwsA(isA<Exception>()));
    });

    test('without a retry the first result is used again', () async {
      final pending = _pending(Future.value(_onDisk));
      await _wait(pending);

      expect((await _wait(pending))?.filePath, '/tmp/a.pdf');
    });

    test(
      'keeps the path of the saved file, so a stored upload can retry',
      () async {
        final pending = _pending(Future.value(_onDisk));
        expect(pending.toJson()['filePath'], isNull);

        await _wait(pending);

        expect(pending.toJson()['filePath'], '/tmp/a.pdf');
      },
    );
  });
}
