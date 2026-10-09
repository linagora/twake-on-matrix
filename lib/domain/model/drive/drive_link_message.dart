import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';

part 'drive_link_message.freezed.dart';

const driveFileContentKey = 'app.twake.drive.file';

@freezed
abstract class DriveLinkMessage with _$DriveLinkMessage {
  const DriveLinkMessage._();

  const factory DriveLinkMessage({
    required String fileId,
    required String name,
    required int size,
    required String mimeType,
    required Uri url,
    Uri? thumbnailUrl,
  }) = _DriveLinkMessage;

  /// Returns null when the document has no link that can be shared.
  static DriveLinkMessage? fromDocument(DrivePickedEntry document) {
    final url = document.sharingLink;
    if (url == null) return null;
    return DriveLinkMessage(
      fileId: document.id,
      name: document.name,
      size: document.size,
      mimeType: document.mimeTypeOrDefault,
      url: url,
      thumbnailUrl: document.thumbnailLink,
    );
  }

  String get body => '$name\n$url';
}
