import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_chat/domain/drive/sources/drive_file_download_source.dart';

class DownloadDriveFilesUseCase {
  const DownloadDriveFilesUseCase(this._source);

  final DriveFileDownloadSource _source;

  /// One outcome per file, in the order given. A file whose size is known to
  /// be over [maxBytes] is refused before any byte moves; the others are
  /// downloaded and checked again as they come. [onOutcome] hears each file's
  /// outcome, with its index in [files], as soon as it is known.
  Future<List<DriveDownloadOutcome>> execute(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  }) async {
    final limit = maxBytes;
    bool tooLarge(DrivePickedFile file) => limit != null && file.size > limit;
    // Where each accepted file sits in [files].
    final indexes = [
      for (var i = 0; i < files.length; i++)
        if (!tooLarge(files[i])) i,
    ];
    for (var i = 0; i < files.length; i++) {
      if (tooLarge(files[i])) {
        onOutcome?.call(
          i,
          DriveDownloadRejected(files[i], DriveDownloadFailure.tooLarge),
        );
      }
    }
    final downloaded = await _source.downloadAll(
      [for (final i in indexes) files[i]],
      maxBytes: limit,
      onOutcome: onOutcome == null
          ? null
          : (accepted, outcome) => onOutcome(indexes[accepted], outcome),
    );
    var acceptedIndex = 0;
    return [
      for (final file in files)
        tooLarge(file)
            ? DriveDownloadRejected(file, DriveDownloadFailure.tooLarge)
            : downloaded[acceptedIndex++],
    ];
  }
}
