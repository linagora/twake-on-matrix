import 'package:twake_chat/domain/model/file_info/file_info.dart';

/// A file whose bytes are still on their way, for example from Twake Drive.
///
/// The upload queue shows it from its name, size and type, and waits for
/// [resolved] before it reads it. It never reaches a database: it lives in
/// memory with the queue.
class PendingFileInfo extends FileInfo {
  PendingFileInfo(
    super.fileName, {
    required this.size,
    required this.resolved,
    this.retry,
    super.customMimeType,
  }) {
    // A failure is read by `whenReady`; until the queue gets there, or when the
    // user cancelled first, nobody listens and it must not surface.
    resolved.ignore();
  }

  /// The size the source announced, as the file is not on disk yet.
  final int size;

  /// The file once it is on disk, or an error when it never will be.
  final Future<FileInfo> resolved;

  /// Brings the file again for a retry of the upload: [resolved] is spent by
  /// then, and it may have failed. Null when it cannot be brought twice.
  final Future<FileInfo> Function()? retry;

  /// What changes while the queue works on it; the file info itself does not.
  final _progress = _Progress();

  @override
  int get fileSize => size;

  /// The path of the saved file once it came, so a failed upload that is
  /// stored keeps it for a retry after a restart.
  @override
  String? get filePath => _progress.saved?.filePath;

  Future<FileInfo> _nextAttempt() {
    final again = retry;
    if (_progress.attempts++ == 0 || again == null) return resolved;
    final attempt = again();
    attempt.ignore();
    return attempt;
  }

  /// The file once it is on disk, or null when [cancelled] says the user gave
  /// it up while its bytes were on their way: the queue then sends nothing.
  /// [onCancelled] completes when the user gives it up, so the queue is free
  /// at once and does not wait for a download nobody wants.
  /// Throws when the file never arrived and nobody cancelled.
  Future<FileInfo?> whenReady({
    required bool Function() cancelled,
    required Future<void> onCancelled,
  }) async {
    try {
      final file = await Future.any<FileInfo?>([
        _nextAttempt(),
        onCancelled.then<FileInfo?>((_) => null),
      ]);
      if (cancelled()) return null;
      _progress.saved = file;
      return file;
    } on Exception {
      if (cancelled()) return null;
      rethrow;
    }
  }

  @override
  List<Object?> get props => [...super.props, size];
}

class _Progress {
  int attempts = 0;
  FileInfo? saved;
}
