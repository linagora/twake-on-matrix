import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/sources/drive_file_download_source.dart';
import 'package:twake_chat/domain/drive/usecases/download_drive_files_usecase.dart';

DrivePickedFile _file(String name, int size) => DrivePickedFile(
  id: name,
  name: name,
  size: size,
  downloadUri: Uri.parse('https://x.example/d/$name'),
);

class _FakeSource implements DriveFileDownloadSource {
  List<DrivePickedFile> asked = [];
  int? askedMax;
  final failing = <String>{};

  /// Tells the outcomes last file first, as downloads that finish out of order.
  bool reversed = false;

  @override
  Future<List<DriveDownloadOutcome>> downloadAll(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  }) async {
    asked = files;
    askedMax = maxBytes;
    final outcomes = [
      for (final (index, file) in files.indexed)
        failing.contains(file.name)
            ? DriveDownloadRejected(file, DriveDownloadFailure.failed)
            : DriveDownloaded(
                DriveDownloadedFile(
                  name: file.name,
                  path: '/tmp/${index}_${file.name}',
                  size: file.size,
                ),
              ),
    ];
    final order = [for (var i = 0; i < outcomes.length; i++) i];
    for (final i in reversed ? order.reversed : order) {
      onOutcome?.call(i, outcomes[i]);
    }
    return outcomes;
  }
}

void main() {
  late _FakeSource source;
  late DownloadDriveFilesUseCase useCase;

  setUp(() {
    source = _FakeSource();
    useCase = DownloadDriveFilesUseCase(source);
  });

  group('DownloadDriveFilesUseCase.execute', () {
    test('tells each outcome with the index of its own file', () async {
      source.reversed = true;
      final told = <int, String>{};

      await useCase.execute(
        [_file('a', 1), _file('b', 2), _file('c', 3)],
        maxBytes: null,
        onOutcome: (index, outcome) =>
            told[index] = (outcome as DriveDownloaded).file.name,
      );

      expect(told, {0: 'a', 1: 'b', 2: 'c'});
    });

    test('downloads every file and answers in the order given', () async {
      final outcomes = await useCase.execute([
        _file('a', 1),
        _file('b', 2),
      ], maxBytes: null);

      expect(outcomes.whereType<DriveDownloaded>().map((o) => o.file.name), [
        'a',
        'b',
      ]);
      expect(source.askedMax, isNull);
    });

    test('tells each outcome with its place in the list given', () async {
      final heard = <(int, String)>[];

      await useCase.execute(
        [_file('a', 10), _file('big', 101), _file('c', 5)],
        maxBytes: 100,
        onOutcome: (index, outcome) => heard.add((
          index,
          switch (outcome) {
            DriveDownloaded(:final file) => file.name,
            DriveDownloadRejected(:final source) => 'rejected:${source.name}',
          },
        )),
      );

      expect(heard, [(1, 'rejected:big'), (0, 'a'), (2, 'c')]);
    });

    test(
      'refuses a file known to be over the limit before it moves a byte',
      () async {
        final outcomes = await useCase.execute([
          _file('a', 10),
          _file('big', 101),
          _file('c', 5),
        ], maxBytes: 100);

        expect(source.asked.map((f) => f.name), ['a', 'c']);
        expect(
          outcomes[1],
          isA<DriveDownloadRejected>().having(
            (o) => o.reason,
            'reason',
            DriveDownloadFailure.tooLarge,
          ),
        );
        expect(outcomes[0], isA<DriveDownloaded>());
        expect(outcomes[2], isA<DriveDownloaded>());
      },
    );

    test('a file exactly at the limit is accepted', () async {
      final outcomes = await useCase.execute([_file('a', 100)], maxBytes: 100);

      expect(outcomes.single, isA<DriveDownloaded>());
    });

    test(
      'passes the limit on, so a size the server hides is still caught',
      () async {
        await useCase.execute([_file('a', 1)], maxBytes: 100);

        expect(source.askedMax, 100);
      },
    );

    test('one failing file does not hide the others', () async {
      source.failing.add('b');

      final outcomes = await useCase.execute([
        _file('a', 1),
        _file('b', 1),
        _file('c', 1),
      ], maxBytes: null);

      expect(outcomes[0], isA<DriveDownloaded>());
      expect(outcomes[1], isA<DriveDownloadRejected>());
      expect(outcomes[2], isA<DriveDownloaded>());
    });

    test('equal picks keep their separate download outcomes', () async {
      final file = _file('same', 1);

      final outcomes = await useCase.execute([file, file], maxBytes: null);

      expect(source.asked, hasLength(2));
      expect(outcomes, hasLength(2));
      expect(
        outcomes.whereType<DriveDownloaded>().map((o) => o.file.path).toSet(),
        hasLength(2),
      );
    });

    test('no files gives no outcomes', () async {
      final outcomes = await useCase.execute(const [], maxBytes: 100);

      expect(outcomes, isEmpty);
    });
  });
}
