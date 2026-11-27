import 'package:twake_chat/domain/exception/room/can_not_upload_content_exception.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/presentation/model/file/file_asset_entity.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

extension AssetEntityAvatarUpload on AssetEntity {
  /// Throws [SaveOwnProfileException] when the picked file cannot be read.
  Future<AvatarUpload> toAvatarUpload() async {
    try {
      final info = await FileAssetEntity.createAssetEntity(this).toFileInfo();
      final path = info?.filePath;
      if (info == null || path == null) throw CannotUploadContentException();
      return AvatarUpload.fromFile(
        path: path,
        name: info.fileName,
        mimeType: info.customMimeType,
      );
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(SaveOwnProfileException(e), s);
    }
  }
}
