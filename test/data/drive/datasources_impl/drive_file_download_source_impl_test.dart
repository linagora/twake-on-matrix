import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_file_download_source_impl.dart';
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

import '../support/fake_http_adapter.dart';

DrivePickedFile _file(String name, {String? url, int size = 1}) =>
    DrivePickedFile(
      id: name,
      name: name,
      size: size,
      mimeType: 'application/pdf',
      downloadUri: Uri.parse(url ?? 'https://drive.example/d/$name'),
    );

ResponseBody _bytes(List<int> data, {bool announce = true, int status = 200}) =>
    ResponseBody.fromBytes(
      Uint8List.fromList(data),
      status,
      headers: {
        if (announce) Headers.contentLengthHeader: ['${data.length}'],
      },
    );

Matcher _rejected(DriveDownloadFailure reason) =>
    isA<DriveDownloadRejected>().having((o) => o.reason, 'reason', reason);

void main() {
  late Directory temp;
  late FakeHttpAdapter adapter;
  late ResponseBody Function(RequestOptions) answer;
  late DateTime now;
  var ids = 0;

  DriveFileDownloadSourceImpl source({
    bool requireHttps = true,
    int concurrency = 3,
    Duration downloadTimeout = const Duration(minutes: 5),
    Duration idleTimeout = const Duration(seconds: 30),
    Dio? client,
    Future<Directory> Function()? tempRoot,
  }) => DriveFileDownloadSourceImpl(
    dio: client ?? (Dio()..httpClientAdapter = adapter),
    tempRoot: tempRoot ?? () async => temp,
    randomId: () => 'r${ids++}',
    now: () => now,
    staleAfter: const Duration(days: 1),
    requireHttps: requireHttps,
    concurrency: concurrency,
    downloadTimeout: downloadTimeout,
    idleTimeout: idleTimeout,
  );

  Directory picks() =>
      Directory('${temp.path}/${DriveFileDownloadSourceImpl.folderName}');

  List<File> savedFiles() =>
      picks().listSync(recursive: true).whereType<File>().toList();

  /// Answers every request with a stream that announces [length] bytes and
  /// never sends them. Completes when the source closes the stream.
  Future<void> answerWithStreamAnnouncing(int length) {
    final cancelled = Completer<void>();
    final stream = StreamController<Uint8List>(onCancel: cancelled.complete);
    answer = (options) => ResponseBody(
      stream.stream,
      200,
      headers: {
        Headers.contentLengthHeader: ['$length'],
      },
    );
    return cancelled.future;
  }

  setUp(() {
    temp = Directory.systemTemp.createTempSync('drive_download_test');
    now = DateTime.utc(2026, 11, 4, 12);
    ids = 0;
    answer = (options) => _bytes([1, 2, 3]);
    adapter = FakeHttpAdapter((options) => answer(options));
  });

  tearDown(() => temp.deleteSync(recursive: true));

  group('DriveFileDownloadSourceImpl.downloadAll', () {
    test(
      'saves each file under the folder of the pick and reports its size',
      () async {
        final outcomes = await source().downloadAll([
          _file('a.pdf'),
        ], maxBytes: null);

        final saved = (outcomes.single as DriveDownloaded).file;
        expect(saved.name, 'a.pdf');
        expect(saved.size, 3);
        expect(saved.mimeType, 'application/pdf');
        expect(File(saved.path).readAsBytesSync(), [1, 2, 3]);
        expect(saved.path, startsWith(picks().path));
      },
    );

    test('answers one outcome per file, in order', () async {
      final outcomes = await source().downloadAll([
        _file('a'),
        _file('b'),
        _file('c'),
      ], maxBytes: null);

      expect(outcomes.map((o) => (o as DriveDownloaded).file.name), [
        'a',
        'b',
        'c',
      ]);
    });

    test('two files with the same name do not overwrite each other', () async {
      final outcomes = await source().downloadAll([
        _file('same.pdf'),
        _file('same.pdf'),
      ], maxBytes: null);

      final paths = outcomes
          .map((o) => (o as DriveDownloaded).file.path)
          .toSet();
      expect(paths, hasLength(2));
    });

    test(
      'sends no Authorization header: the link is the secret, not the Matrix token',
      () async {
        await source().downloadAll([_file('a')], maxBytes: null);

        expect(
          adapter.requests.single.headers.containsKey('Authorization'),
          isFalse,
        );
      },
    );

    test('refuses a file announced over the limit without saving it', () async {
      answer = (options) => _bytes(List.filled(11, 1));

      final outcomes = await source().downloadAll([_file('a')], maxBytes: 10);

      expect(outcomes.single, _rejected(DriveDownloadFailure.tooLarge));
      expect(savedFiles(), isEmpty);
    });

    test('closes an oversized announced response stream', () async {
      final closed = answerWithStreamAnnouncing(11);

      final outcomes = await source().downloadAll([_file('a')], maxBytes: 10);

      expect(outcomes.single, isA<DriveDownloadRejected>());
      await expectLater(closed, completes);
      expect(savedFiles(), isEmpty);
    });

    test('caps an announced file when the server limit is unknown', () async {
      final closed = answerWithStreamAnnouncing(100 * 1024 * 1024 + 1);

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect(outcomes.single, _rejected(DriveDownloadFailure.tooLarge));
      await expectLater(closed, completes);
      expect(savedFiles(), isEmpty);
    });

    test(
      'stops a file over the limit even when the server hides its length',
      () async {
        answer = (options) => _bytes(List.filled(11, 1), announce: false);

        final outcomes = await source().downloadAll([_file('a')], maxBytes: 10);

        expect(outcomes.single, _rejected(DriveDownloadFailure.tooLarge));
        expect(savedFiles(), isEmpty);
      },
    );

    test('a file exactly at the limit is saved', () async {
      answer = (options) => _bytes(List.filled(10, 1));

      final outcomes = await source().downloadAll([_file('a')], maxBytes: 10);

      expect(outcomes.single, isA<DriveDownloaded>());
    });

    test('a trickling stream stops at the total deadline', () async {
      final cancelled = Completer<void>();
      late Timer ticker;
      late final StreamController<Uint8List> stream;
      stream = StreamController<Uint8List>(
        onListen: () {
          ticker = Timer.periodic(
            const Duration(milliseconds: 10),
            (_) => stream.add(Uint8List.fromList([1])),
          );
        },
        onCancel: () {
          ticker.cancel();
          cancelled.complete();
        },
      );
      answer = (options) => ResponseBody(stream.stream, 200);

      final outcomes =
          await source(downloadTimeout: const Duration(milliseconds: 100))
              .downloadAll([_file('a')], maxBytes: null)
              .timeout(const Duration(seconds: 1));

      expect(outcomes.single, _rejected(DriveDownloadFailure.failed));
      await expectLater(cancelled.future, completes);
      expect(savedFiles(), isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(savedFiles(), isEmpty);
    });

    test('a stream that stops sending gives up at the idle timeout, not at the '
        'total deadline', () async {
      final cancelled = Completer<void>();
      late final StreamController<Uint8List> stream;
      stream = StreamController<Uint8List>(
        onListen: () => stream.add(Uint8List.fromList([1, 2])),
        onCancel: cancelled.complete,
      );
      answer = (options) => ResponseBody(stream.stream, 200);

      final outcomes =
          await source(idleTimeout: const Duration(milliseconds: 400))
              .downloadAll([_file('a')], maxBytes: null)
              .timeout(const Duration(seconds: 2));

      expect(outcomes.single, _rejected(DriveDownloadFailure.failed));
      await expectLater(cancelled.future, completes);
      expect(savedFiles(), isEmpty);
    });

    test('tells each outcome as soon as that file is saved', () async {
      final slow = Completer<void>();
      answer = (options) => options.uri.path.contains('slow')
          ? ResponseBody(
              Stream<Uint8List>.fromFuture(
                slow.future.then((_) => Uint8List.fromList([1])),
              ),
              200,
            )
          : _bytes([1, 2, 3]);
      final heard = <int>[];

      final all = source().downloadAll(
        [_file('slow.pdf'), _file('fast.pdf')],
        maxBytes: null,
        onOutcome: (index, outcome) => heard.add(index),
      );
      // Not a fixed wait: a loaded machine takes longer to save the fast file.
      while (heard.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // The fast file is heard while the slow one is still on its way.
      expect(heard, [1]);
      slow.complete();
      final outcomes = await all;
      expect(heard, [1, 0]);
      // The answer keeps the order of the files, whichever finished first.
      expect(outcomes.map((o) => (o as DriveDownloaded).file.name), [
        'slow.pdf',
        'fast.pdf',
      ]);
    });

    test('one stuck file does not hold back the others', () async {
      final stuck = StreamController<Uint8List>();
      answer = (options) => options.uri.path.contains('stuck')
          ? ResponseBody(stuck.stream, 200)
          : _bytes([1, 2, 3]);

      final outcomes =
          await source(idleTimeout: const Duration(milliseconds: 400))
              .downloadAll([
                _file('ok.pdf'),
                _file('stuck.pdf'),
                _file('also-ok.pdf'),
              ], maxBytes: null)
              .timeout(const Duration(seconds: 2));

      expect(outcomes[0], isA<DriveDownloaded>());
      expect(outcomes[1], isA<DriveDownloadRejected>());
      expect(outcomes[2], isA<DriveDownloaded>());
      await stuck.close();
    });

    test('a server error fails that file and leaves no partial file', () async {
      answer = (options) => _bytes([], status: 500);

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect(outcomes.single, _rejected(DriveDownloadFailure.failed));
      expect(savedFiles(), isEmpty);
    });

    test(
      'a connection that breaks mid-file fails that file, not the pick',
      () async {
        answer = (options) => options.path.endsWith('/b')
            ? ResponseBody(
                (() async* {
                  yield Uint8List.fromList([1]);
                  throw const SocketException('connection reset');
                })(),
                200,
              )
            : _bytes([1]);

        final outcomes = await source().downloadAll([
          _file('a'),
          _file('b'),
        ], maxBytes: null);

        expect(outcomes[0], isA<DriveDownloaded>());
        expect(outcomes[1], _rejected(DriveDownloadFailure.failed));
        expect(picks().listSync(recursive: true).whereType<File>().length, 1);
      },
    );

    test('one failing file does not stop the others', () async {
      answer = (options) =>
          options.path.endsWith('/b') ? _bytes([], status: 500) : _bytes([1]);

      final outcomes = await source().downloadAll([
        _file('a'),
        _file('b'),
        _file('c'),
      ], maxBytes: null);

      expect(outcomes[0], isA<DriveDownloaded>());
      expect(outcomes[1], isA<DriveDownloadRejected>());
      expect(outcomes[2], isA<DriveDownloaded>());
    });

    test('a missing response body fails only that file', () async {
      final client = Dio()..httpClientAdapter = adapter;
      client.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            if (response.requestOptions.path.endsWith('/b')) {
              response.data = null;
            }
            handler.next(response);
          },
        ),
      );

      final outcomes = await source(
        client: client,
      ).downloadAll([_file('a'), _file('b'), _file('c')], maxBytes: null);

      expect(outcomes[0], isA<DriveDownloaded>());
      expect(outcomes[1], isA<DriveDownloadRejected>());
      expect(outcomes[2], isA<DriveDownloaded>());
      expect(picks().listSync(recursive: true).whereType<File>(), hasLength(2));
    });

    test(
      'refuses an http link in a release build, before any request',
      () async {
        final outcomes = await source().downloadAll([
          _file('a', url: 'http://drive.example/d/a'),
        ], maxBytes: null);

        expect(outcomes.single, _rejected(DriveDownloadFailure.insecureLink));
        expect(adapter.requests, isEmpty);
      },
    );

    ResponseBody redirectTo(String location) => ResponseBody.fromBytes(
      Uint8List(0),
      302,
      headers: {
        'location': [location],
      },
    );

    test('does not follow a redirect to http when https is required', () async {
      answer = (options) => redirectTo('http://files.example/d/1');

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect(outcomes.single, _rejected(DriveDownloadFailure.insecureLink));
      expect(adapter.requests, hasLength(1));
    });

    test('follows a redirect to another https link', () async {
      answer = (options) => options.uri.host == 'files.example'
          ? _bytes([4, 5])
          : redirectTo('https://files.example/d/1');

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect((outcomes.single as DriveDownloaded).file.size, 2);
      expect(adapter.requests, hasLength(2));
    });

    test('a redirect with no Location is no file', () async {
      answer = (options) => ResponseBody.fromBytes(Uint8List(0), 302);

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect(outcomes.single, _rejected(DriveDownloadFailure.failed));
      expect(savedFiles(), isEmpty);
    });

    test('asks for the file without following a redirect itself', () async {
      await source().downloadAll([_file('a')], maxBytes: null);

      expect(adapter.requests.single.followRedirects, isFalse);
    });

    test('gives up on a redirect that never ends', () async {
      answer = (options) => redirectTo('https://x.example/loop');

      final outcomes = await source().downloadAll([_file('a')], maxBytes: null);

      expect(outcomes.single, _rejected(DriveDownloadFailure.failed));
    });

    test('a folder that cannot be made fails each file and tells it', () async {
      final told = <int>[];
      final failing = source(tempRoot: () async => throw Exception('no disk'));

      final outcomes = await failing.downloadAll(
        [_file('a'), _file('b')],
        maxBytes: null,
        onOutcome: (index, outcome) => told.add(index),
      );

      expect(outcomes, hasLength(2));
      expect(outcomes, everyElement(_rejected(DriveDownloadFailure.failed)));
      expect(told, [0, 1]);
    });

    test('accepts an http link when https is not required (debug)', () async {
      final outcomes = await source(requireHttps: false).downloadAll([
        _file('a', url: 'http://drive.example/d/a'),
      ], maxBytes: null);

      expect(outcomes.single, isA<DriveDownloaded>());
    });

    test('runs at most the allowed number of downloads at once', () async {
      var running = 0;
      var peak = 0;
      final gates = <Completer<void>>[];
      adapter = FakeHttpAdapter((options) => _bytes([1]));
      final slow = DriveFileDownloadSourceImpl(
        dio: Dio()
          ..httpClientAdapter = _SlowAdapter(
            onStart: () {
              running++;
              if (running > peak) peak = running;
              final gate = Completer<void>();
              gates.add(gate);
              return gate.future.whenComplete(() => running--);
            },
          ),
        tempRoot: () async => temp,
        randomId: () => 'r${ids++}',
        now: () => now,
        staleAfter: const Duration(days: 1),
        requireHttps: true,
        concurrency: 2,
      );

      final pending = slow.downloadAll([
        for (var i = 0; i < 5; i++) _file('f$i'),
      ], maxBytes: null);
      // Release whatever is in flight, wave after wave, until all are done.
      var finished = false;
      unawaited(pending.whenComplete(() => finished = true));
      while (!finished) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        for (final gate in gates.where((g) => !g.isCompleted)) {
          gate.complete();
        }
      }
      final outcomes = await pending;

      expect(outcomes, hasLength(5));
      expect(peak, lessThanOrEqualTo(2));
    });

    test('no files means no folder and no request', () async {
      final outcomes = await source().downloadAll(const [], maxBytes: null);

      expect(outcomes, isEmpty);
      expect(picks().existsSync(), isFalse);
      expect(adapter.requests, isEmpty);
    });
  });

  group('DriveFileDownloadSourceImpl.safeName', () {
    final cases = <String, String>{
      'report.pdf': 'report.pdf',
      '../../etc/passwd': 'passwd',
      r'..\..\evil.exe': 'evil.exe',
      'a/b/c.txt': 'c.txt',
      'bad:name?.txt': 'bad_name_.txt',
      '': 'file',
      '..': 'file',
      '.': 'file',
      '   ': 'file',
    };
    for (final entry in cases.entries) {
      test('"${entry.key}" becomes "${entry.value}"', () {
        expect(DriveFileDownloadSourceImpl.safeName(entry.key), entry.value);
      });
    }

    test('a control character is replaced', () {
      expect(DriveFileDownloadSourceImpl.safeName('a\u0000b.txt'), 'a_b.txt');
    });

    test('a name is cut by its UTF-8 bytes, not its characters', () {
      final name = DriveFileDownloadSourceImpl.safeName('${'文' * 90}.pdf');

      expect(utf8.encode(name).length, lessThanOrEqualTo(120));
      expect(name, endsWith('.pdf'));
      expect(name, isNot(contains('\uFFFD')));
    });

    test('a long name is cut but keeps its extension', () {
      final name = DriveFileDownloadSourceImpl.safeName('${'x' * 300}.pdf');

      expect(name.length, 120);
      expect(name, endsWith('.pdf'));
    });

    test('an extension longer than the limit does not throw', () {
      final name = DriveFileDownloadSourceImpl.safeName('a.${'e' * 300}');

      expect(name.length, 120);
    });

    test('a name that stays on disk never leaves the pick folder', () async {
      adapter = FakeHttpAdapter((options) => _bytes([1]));
      final outcomes = await source().downloadAll([
        _file('../../escape.txt'),
      ], maxBytes: null);

      final saved = (outcomes.single as DriveDownloaded).file;
      expect(saved.path, startsWith(picks().path));
      expect(saved.name, 'escape.txt');
    });
  });

  group('DriveFileDownloadSourceImpl stale folders', () {
    Directory pickFolder(DateTime at, String id) =>
        Directory('${picks().path}/${at.millisecondsSinceEpoch}_$id')
          ..createSync(recursive: true);

    test(
      'a later pick removes the folders older than a day and keeps the recent ones',
      () async {
        final old = pickFolder(now.subtract(const Duration(days: 2)), 'old')
          ..childFile().writeAsBytesSync([1]);
        final recent = pickFolder(
          now.subtract(const Duration(hours: 1)),
          'recent',
        )..childFile().writeAsBytesSync([1]);

        await source().downloadAll([_file('a')], maxBytes: null);

        expect(old.existsSync(), isFalse);
        expect(recent.existsSync(), isTrue);
      },
    );

    test('leaves a folder it did not make', () async {
      final foreign = Directory('${picks().path}/not-ours')
        ..createSync(recursive: true);

      await source().downloadAll([_file('a')], maxBytes: null);

      expect(foreign.existsSync(), isTrue);
    });
  });
}

extension on Directory {
  File childFile() => File('$path/file.bin');
}

/// An adapter whose answer waits for the test, to count downloads in flight.
class _SlowAdapter implements HttpClientAdapter {
  _SlowAdapter({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await onStart();
    return _bytes([1]);
  }

  @override
  void close({bool force = false}) {}
}
