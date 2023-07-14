
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/presentation/extensions/asset_entity_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class UploadContentInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required AssetEntity entity,
  }) async* {
    try {
      yield Right(UploadContentLoading());
      final matrixFile = await entity.toMatrixFile();
      final mediaConfig = await matrixClient.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      if (matrixFile != null) {
        final fileSize = matrixFile.bytes.length;
        Logs().d('SendImage::sendImageFileEvent(): FileSized $fileSize || maxMediaSize $maxMediaSize');
        if (maxMediaSize != null && maxMediaSize < fileSize) {
          yield Left(FileTooBigMatrix(FileTooBigMatrixException(fileSize, maxMediaSize)));
        }
        final uri = await matrixClient.uploadContent(
          matrixFile.bytes,
          filename: matrixFile.name,
          contentType: matrixFile.mimeType,
        );
        yield Right(UploadContentSuccess(uri: uri, file: matrixFile.bytes));
      } else {
        yield const Left(UploadContentFailed(exception: null));
      }
    } catch (exception) {
      yield Left(UploadContentFailed(exception: exception));
    }
  }
}