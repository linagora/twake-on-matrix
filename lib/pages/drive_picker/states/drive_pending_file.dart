import 'dart:async';
import 'dart:io';

import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

/// A picked file that the chat already shows while its bytes are on their way.
/// [ready] completes with the saved file, or with [DriveFileNotReceived] when
/// it never arrived.
final class DrivePendingFile {
  DrivePendingFile(this.source, {this.download}) {
    // The upload queue listens when its turn comes; until then a failure is
    // not an unhandled error.
    _done.future.ignore();
  }

  final DrivePickedFile source;

  /// Downloads [source] again, for the retry of an upload; null when this file
  /// cannot be fetched a second time.
  final Future<DriveDownloadOutcome> Function(DrivePickedFile source)? download;
  final _done = Completer<DriveDownloadedFile>();
  DriveDownloadedFile? _saved;

  Future<DriveDownloadedFile> get ready => _done.future;

  /// The outcome of [source]. Only the first answer counts.
  void resolve(DriveDownloadOutcome outcome) {
    if (_done.isCompleted) return;
    switch (outcome) {
      case DriveDownloaded(:final file):
        _saved = file;
        _done.complete(file);
      case DriveDownloadRejected(:final reason):
        _done.completeError(DriveFileNotReceived(reason));
    }
  }

  /// The file for a retry of its upload: the one already saved while it is
  /// still on disk, else a new download. Throws [DriveFileNotReceived] when
  /// that does not come either (the link may have expired by now).
  Future<DriveDownloadedFile> again() async {
    final saved = _saved;
    if (saved != null && await File(saved.path).exists()) return saved;
    return _saved = await _downloadAgain();
  }

  Future<DriveDownloadedFile> _downloadAgain() async {
    final fetch = download;
    if (fetch == null) {
      throw const DriveFileNotReceived(DriveDownloadFailure.failed);
    }
    final DriveDownloadOutcome outcome;
    try {
      outcome = await fetch(source);
    } on Exception {
      throw const DriveFileNotReceived(DriveDownloadFailure.failed);
    }
    return switch (outcome) {
      DriveDownloaded(:final file) => file,
      DriveDownloadRejected(:final reason) => throw DriveFileNotReceived(
        reason,
      ),
    };
  }

  /// [source] will not come: the download ended without answering for it.
  void fail() =>
      resolve(DriveDownloadRejected(source, DriveDownloadFailure.failed));
}

/// What the upload queue sees for a file Drive did not deliver.
final class DriveFileNotReceived implements Exception {
  const DriveFileNotReceived(this.reason);

  final DriveDownloadFailure reason;
}
