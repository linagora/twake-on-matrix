import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';
import 'package:path/path.dart' as p;
import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/sources/drive_file_download_source.dart';

/// Saves picked files to a temporary folder of their own, a few at a time.
///
/// The [Dio] must not add the Matrix token: the link is a secret of Drive's and
/// the Matrix server is not its owner. Logs say which step failed, never a
/// link or a file name.
class DriveFileDownloadSourceImpl implements DriveFileDownloadSource {
  DriveFileDownloadSourceImpl({
    required Dio dio,
    required Future<Directory> Function() tempRoot,
    required String Function() randomId,
    required DateTime Function() now,
    required Duration staleAfter,
    required bool requireHttps,
    required int concurrency,
    Duration downloadTimeout = const Duration(minutes: 5),
    Duration idleTimeout = const Duration(seconds: 30),
  }) : _dio = dio,
       _tempRoot = tempRoot,
       _randomId = randomId,
       _now = now,
       _staleAfter = staleAfter,
       _requireHttps = requireHttps,
       _concurrency = concurrency,
       _downloadTimeout = downloadTimeout,
       _idleTimeout = idleTimeout;

  /// The folder of one pick sits under this name, so the cleanup can tell it
  /// from any other folder before it deletes.
  static const folderName = 'drive_picks';

  // The same local ceiling as the app's placeholder attachment limit. It
  // bounds disk use when the homeserver has no configured upload limit.
  static const _fallbackMaxBytes = 100 * 1024 * 1024;

  final Dio _dio;
  final Future<Directory> Function() _tempRoot;
  final String Function() _randomId;
  final DateTime Function() _now;
  final Duration _staleAfter;
  final bool _requireHttps;
  final int _concurrency;
  final Duration _downloadTimeout;

  /// A file that gets no byte for this long is given up: one stuck file must
  /// not hold the others until the total deadline.
  final Duration _idleTimeout;

  @override
  Future<List<DriveDownloadOutcome>> downloadAll(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  }) async {
    if (files.isEmpty) return const [];
    final Directory folder;
    try {
      folder = await _prepareFolder();
    } on Exception {
      // No folder to save in: every file fails, and each is told.
      Logs().w('DriveFileDownloadSourceImpl::download: no folder to save in');
      final outcomes = <DriveDownloadOutcome>[
        for (final file in files)
          DriveDownloadRejected(file, DriveDownloadFailure.failed),
      ];
      for (var i = 0; i < outcomes.length; i++) {
        onOutcome?.call(i, outcomes[i]);
      }
      return outcomes;
    }

    final outcomes = List<DriveDownloadOutcome?>.filled(files.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < files.length) {
        final index = next++;
        final outcome = await _download(
          files[index],
          folder: folder,
          index: index,
          maxBytes: maxBytes,
        );
        outcomes[index] = outcome;
        onOutcome?.call(index, outcome);
      }
    }

    await Future.wait(
      List.generate(min(_concurrency, files.length), (_) => worker()),
    );
    return outcomes.whereType<DriveDownloadOutcome>().toList();
  }

  Future<Directory> _prepareFolder() async {
    final root = Directory(p.join((await _tempRoot()).path, folderName));
    await _deleteStaleFolders(root);
    // The name starts with the time, so a later run knows how old it is.
    final folder = Directory(
      p.join(root.path, '${_now().millisecondsSinceEpoch}_${_randomId()}'),
    );
    await folder.create(recursive: true);
    return folder;
  }

  /// The files of a pick are read again by the upload queue, until the upload
  /// ends and on every retry, so nobody can say when they are free. A later
  /// pick removes the folders of earlier ones that are older than
  /// [_staleAfter].
  /// TODO: [transitional] ToM-Private#3: tie cleanup to upload completion;
  /// a retry lasting longer than [_staleAfter] can still need these files.
  Future<void> _deleteStaleFolders(Directory root) async {
    if (!await root.exists()) return;
    final limit = _now().subtract(_staleAfter).millisecondsSinceEpoch;
    final List<FileSystemEntity> entries;
    try {
      entries = await root.list().toList();
    } on FileSystemException catch (e) {
      Logs().w('DriveFileDownloadSourceImpl::stale: ${e.osError?.errorCode}');
      return;
    }
    for (final entry in entries) {
      final stamp = int.tryParse(p.basename(entry.path).split('_').first);
      if (entry is! Directory || stamp == null || stamp >= limit) continue;
      try {
        await entry.delete(recursive: true);
      } on FileSystemException catch (e) {
        Logs().w('DriveFileDownloadSourceImpl::stale: ${e.osError?.errorCode}');
      }
    }
  }

  Future<DriveDownloadOutcome> _download(
    DrivePickedFile source, {
    required Directory folder,
    required int index,
    required int? maxBytes,
  }) async {
    final uri = source.downloadUri;
    if (uri == null || !_isAllowed(uri)) {
      return DriveDownloadRejected(source, DriveDownloadFailure.insecureLink);
    }
    final name = safeName(source.name);
    final target = File(p.join(folder.path, '${index}_$name'));
    final byteLimit = maxBytes ?? _fallbackMaxBytes;
    final stopwatch = Stopwatch()..start();
    final cancelToken = CancelToken();
    final deadline = Timer(_downloadTimeout, cancelToken.cancel);
    try {
      final response = await _get(uri, cancelToken);
      if (response == null) {
        return DriveDownloadRejected(source, DriveDownloadFailure.insecureLink);
      }
      final body = response.data;
      if (body == null) throw const FormatException('missing download body');
      final announced = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (announced != null && announced > byteLimit) {
        await _cancelBody(body, cancelToken);
        return DriveDownloadRejected(source, DriveDownloadFailure.tooLarge);
      }
      final remaining = _downloadTimeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        await _cancelBody(body, cancelToken);
        throw TimeoutException('Drive download deadline exceeded');
      }
      final received = await _save(
        body,
        target,
        maxBytes: byteLimit,
        timeout: remaining,
        cancelToken: cancelToken,
      );
      return DriveDownloaded(
        DriveDownloadedFile(
          name: name,
          path: target.path,
          size: received,
          mimeType: source.mimeType,
        ),
      );
    } on _TooLarge {
      await _deleteQuietly(target);
      return DriveDownloadRejected(source, DriveDownloadFailure.tooLarge);
    } on DioException catch (e) {
      Logs().w(
        'DriveFileDownloadSourceImpl::download: ${e.type.name}, '
        'status ${e.response?.statusCode}',
      );
      await _deleteQuietly(target);
      return DriveDownloadRejected(source, DriveDownloadFailure.failed);
    } on FileSystemException catch (e) {
      Logs().w(
        'DriveFileDownloadSourceImpl::download: disk ${e.osError?.errorCode}',
      );
      await _deleteQuietly(target);
      return DriveDownloadRejected(source, DriveDownloadFailure.failed);
    } on Exception {
      // A connection that breaks mid-stream (socket, protocol, timeout).
      Logs().w('DriveFileDownloadSourceImpl::download: the stream broke');
      await _deleteQuietly(target);
      return DriveDownloadRejected(source, DriveDownloadFailure.failed);
    } finally {
      deadline.cancel();
    }
  }

  /// Writes the stream to [target]. Cancelling its subscription before closing
  /// the sink prevents a timed-out response from writing after cleanup.
  Future<int> _save(
    ResponseBody body,
    File target, {
    required int maxBytes,
    required Duration timeout,
    required CancelToken cancelToken,
  }) async {
    final sink = target.openWrite();
    // A failed write is read through the flush and the close below, per file.
    sink.done.ignore();
    var received = 0;
    final done = Completer<int>();
    StreamSubscription<Uint8List>? subscription;
    Timer? timer;
    Timer? idle;
    void giveUp(String reason) {
      if (done.isCompleted) return;
      done.completeError(TimeoutException(reason));
      cancelToken.cancel();
    }

    void waitForNextChunk() {
      idle?.cancel();
      idle = Timer(_idleTimeout, () => giveUp('Drive download stalled'));
    }

    try {
      waitForNextChunk();
      subscription = body.stream.listen(
        (chunk) {
          if (done.isCompleted) return;
          waitForNextChunk();
          received += chunk.length;
          if (received > maxBytes) {
            if (!done.isCompleted) done.completeError(const _TooLarge());
            return;
          }
          sink.add(chunk);
          // The next chunk waits for the disk: three downloads that arrive
          // faster than they are written would fill the memory.
          subscription?.pause();
          unawaited(
            sink.flush().then<void>(
              (_) => subscription?.resume(),
              onError: (Object error, StackTrace stack) {
                if (!done.isCompleted) done.completeError(error, stack);
              },
            ),
          );
        },
        onError: (Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        },
        onDone: () {
          if (!done.isCompleted) done.complete(received);
        },
        cancelOnError: true,
      );
      timer = Timer(timeout, () => giveUp('Drive download deadline exceeded'));
      return await done.future;
    } finally {
      timer?.cancel();
      idle?.cancel();
      if (subscription != null) await subscription.cancel();
      await sink.close();
    }
  }

  static const _maxRedirects = 5;

  /// The answer to [uri], with each redirect checked before it is followed:
  /// Dio would follow one to http, in the clear, in a release build. Null when
  /// a redirect leaves the allowed schemes.
  Future<Response<ResponseBody>?> _get(Uri uri, CancelToken cancelToken) async {
    var current = uri;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final response = await _dio.get<ResponseBody>(
        current.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
        cancelToken: cancelToken,
      );
      final status = response.statusCode ?? 0;
      if (status < 300) return response;
      final location = response.headers.value('location');
      await response.data?.stream.listen(null).cancel();
      // A redirect with nowhere to go is no file: not saved as one.
      if (location == null) {
        throw DioException.badResponse(
          statusCode: status,
          requestOptions: response.requestOptions,
          response: response,
        );
      }
      current = current.resolve(location);
      if (!_isAllowed(current)) return null;
    }
    throw DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.badResponse,
    );
  }

  Future<void> _cancelBody(ResponseBody body, CancelToken cancelToken) async {
    try {
      await body.stream.listen(null).cancel();
    } finally {
      cancelToken.cancel();
    }
  }

  bool _isAllowed(Uri uri) =>
      uri.hasAuthority &&
      (uri.isScheme('https') || (!_requireHttps && uri.isScheme('http')));

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nothing more to do: the folder is in the temporary directory.
    }
  }

  /// A file name that is safe on disk and in a Matrix event: no folder, no
  /// separator, no control character, not empty, and at most [maxNameBytes]
  /// bytes of UTF-8 (a file system limits the bytes of a name, not its
  /// characters), cut between characters.
  static String safeName(String name) {
    final base = p.basename(name.replaceAll('\\', '/'));
    final cleaned = base.replaceAll(RegExp(r'[\x00-\x1f:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') return 'file';
    if (utf8.encode(cleaned).length <= maxNameBytes) return cleaned;
    final extension = p.extension(cleaned);
    // An extension that fills the limit cannot be kept.
    final keep = utf8.encode(extension).length < maxNameBytes;
    final suffix = keep ? extension : '';
    final stem = cleaned.substring(0, cleaned.length - suffix.length);
    return '${_cutToBytes(stem, maxNameBytes - utf8.encode(suffix).length)}'
        '$suffix';
  }

  static const maxNameBytes = 120;

  static String _cutToBytes(String text, int budget) {
    final kept = StringBuffer();
    var used = 0;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      used += utf8.encode(character).length;
      if (used > budget) break;
      kept.write(character);
    }
    return kept.toString();
  }
}

class _TooLarge implements Exception {
  const _TooLarge();
}
