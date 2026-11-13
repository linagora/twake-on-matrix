import 'package:twake_chat/domain/drive/entities/drive_download_outcome.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

/// Where the bytes of a picked file go: a temporary file per pick.
abstract interface class DriveFileDownloadSource {
  /// Downloads [files], some at a time, and answers one outcome per file, in
  /// the same order. It does not throw for a file that fails: that file's
  /// outcome says why. A file bigger than [maxBytes] (when set) is rejected,
  /// even if its size was not known up front. [onOutcome] hears each file's
  /// outcome, with its index in [files], as soon as that file is done.
  Future<List<DriveDownloadOutcome>> downloadAll(
    List<DrivePickedFile> files, {
    required int? maxBytes,
    void Function(int index, DriveDownloadOutcome outcome)? onOutcome,
  });
}
