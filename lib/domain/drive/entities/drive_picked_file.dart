import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picked_file.freezed.dart';

/// One file or folder the user picked in Drive.
@freezed
abstract class DrivePickedFile with _$DrivePickedFile {
  const factory DrivePickedFile({
    required String id,
    required String name,
    required int size,
    String? mimeType,

    /// Public sharing link; set when the user chose to send a link.
    Uri? shareUri,

    /// Short-lived link to the bytes; set when the user chose to attach.
    Uri? downloadUri,
  }) = _DrivePickedFile;
}
