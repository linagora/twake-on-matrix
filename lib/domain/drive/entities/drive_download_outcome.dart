import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

part 'drive_download_outcome.freezed.dart';

/// A picked file saved to a temporary file.
@freezed
abstract class DriveDownloadedFile with _$DriveDownloadedFile {
  const factory DriveDownloadedFile({
    required String name,
    required String path,
    required int size,
    String? mimeType,
  }) = _DriveDownloadedFile;
}

enum DriveDownloadFailure {
  /// The link is not https in a release build.
  insecureLink,

  /// Bigger than the homeserver accepts.
  tooLarge,

  /// Network, server, disk or an answer that is not the file.
  failed,
}

/// The result for one file: one failure never stops the others.
sealed class DriveDownloadOutcome {
  const DriveDownloadOutcome();
}

final class DriveDownloaded extends DriveDownloadOutcome {
  const DriveDownloaded(this.file);

  final DriveDownloadedFile file;
}

final class DriveDownloadRejected extends DriveDownloadOutcome {
  const DriveDownloadRejected(this.source, this.reason);

  final DrivePickedFile source;
  final DriveDownloadFailure reason;
}
