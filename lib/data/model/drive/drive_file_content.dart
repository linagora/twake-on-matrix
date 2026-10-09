// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_file_content.freezed.dart';
part 'drive_file_content.g.dart';

/// Drive data stored in a chat message under `app.twake.drive.file`.
@freezed
abstract class DriveFileContent with _$DriveFileContent {
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  const factory DriveFileContent({
    required String id,
    required String name,
    required int size,
    required String mimeType,
    required Uri url,
    Uri? thumbnailUrl,
  }) = _DriveFileContent;

  factory DriveFileContent.fromJson(Map<String, dynamic> json) =>
      _$DriveFileContentFromJson(json);
}
