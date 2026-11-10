import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/pages/drive_picker/states/drive_pending_file.dart';

final _source = DrivePickedFile(
  id: 'a',
  name: 'a.pdf',
  size: 1,
  mimeType: 'application/pdf',
  downloadUri: Uri.parse('https://drive.example/d/a'),
);

const _saved = DriveDownloadedFile(name: 'a.pdf', path: '/tmp/a.pdf', size: 1);

Matcher _failsWith(DriveDownloadFailure reason) => throwsA(
  isA<DriveFileNotReceived>().having((e) => e.reason, 'reason', reason),
);

/// A pending file whose first download failed, downloaded again by [download].
DrivePendingFile _failedThenDownloadedBy(
  Future<DriveDownloadOutcome> Function(DrivePickedFile source) download,
) => DrivePendingFile(_source, download: download)..fail();

void main() {
  group('DrivePendingFile', () {
    test('is ready with the saved file', () async {
      final file = DrivePendingFile(_source)
        ..resolve(const DriveDownloaded(_saved));

      expect(await file.ready, _saved);
    });

    test('fails with the reason when the download was rejected', () async {
      final file = DrivePendingFile(
        _source,
      )..resolve(DriveDownloadRejected(_source, DriveDownloadFailure.tooLarge));

      await expectLater(file.ready, _failsWith(DriveDownloadFailure.tooLarge));
    });

    test('keeps its first answer', () async {
      final file = DrivePendingFile(_source)
        ..resolve(const DriveDownloaded(_saved))
        ..fail();

      expect(await file.ready, _saved);
    });

    test('a file nobody answered for fails as failed', () async {
      final file = DrivePendingFile(_source)..fail();

      await expectLater(file.ready, _failsWith(DriveDownloadFailure.failed));
    });

    test('a failure before anyone listens is not an unhandled error', () async {
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        DrivePendingFile(_source).fail();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
    });

    group('again', () {
      late Directory dir;
      setUp(() => dir = Directory.systemTemp.createTempSync('pending_file'));
      tearDown(() => dir.deleteSync(recursive: true));

      test('gives the saved file back while it is on disk', () async {
        final path = '${dir.path}/a.pdf';
        File(path).writeAsStringSync('x');
        var downloads = 0;
        final file = DrivePendingFile(
          _source,
          download: (source) async {
            downloads++;
            return DriveDownloadRejected(source, DriveDownloadFailure.failed);
          },
        )..resolve(DriveDownloaded(_saved.copyWith(path: path)));

        expect((await file.again()).path, path);
        expect(downloads, 0);
      });

      test('downloads again when the saved file is gone', () async {
        final path = '${dir.path}/b.pdf';
        final file = DrivePendingFile(
          _source,
          download: (source) async =>
              DriveDownloaded(_saved.copyWith(path: path)),
        )..resolve(const DriveDownloaded(_saved));

        expect((await file.again()).path, path);
      });

      test('downloads again after a failure', () async {
        final file = _failedThenDownloadedBy(
          (source) async => const DriveDownloaded(_saved),
        );

        expect(await file.again(), _saved);
      });

      test('fails with the reason when the new download is rejected', () async {
        final file = _failedThenDownloadedBy(
          (source) async =>
              DriveDownloadRejected(source, DriveDownloadFailure.tooLarge),
        );

        await expectLater(
          file.again(),
          _failsWith(DriveDownloadFailure.tooLarge),
        );
      });

      test('fails when the new download throws', () async {
        final file = _failedThenDownloadedBy(
          (source) async => throw Exception('offline'),
        );

        await expectLater(file.again(), throwsA(isA<DriveFileNotReceived>()));
      });

      test('fails when it cannot be downloaded a second time', () async {
        final file = DrivePendingFile(_source)..fail();

        await expectLater(file.again(), throwsA(isA<DriveFileNotReceived>()));
      });
    });
  });
}
