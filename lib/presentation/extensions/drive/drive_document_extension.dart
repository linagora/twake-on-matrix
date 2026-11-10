import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';
import 'package:twake_drive_picker/core.dart' show DriveDocument;

extension DriveDocumentExtension on DriveDocument {
  /// The picker's document as the domain's picked file, so the domain never
  /// depends on the package.
  DrivePickedFile toPickedFile() => DrivePickedFile(
    id: id,
    name: name,
    size: size,
    mimeType: mimeType,
    shareUri: sharingLink,
    downloadUri: downloadLink,
  );
}
