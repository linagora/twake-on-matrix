import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/upload_content_state.dart';
import 'package:twake_chat/domain/exception/room/can_not_upload_content_exception.dart';
import 'package:twake_chat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class UploadContentInteractor {
  final mediaApi = getIt.get<MediaAPI>();

  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required AssetEntity entity,
  }) async* {
    try {
      yield Right(UploadContentLoading());
      final contentEntity = FileAssetEntity.createAssetEntity(entity);
      final contentFileInfo = await contentEntity.toFileInfo();
      final mediaConfig = await matrixClient.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      if (contentFileInfo != null) {
        final fileSize = contentFileInfo.fileSize;
        Logs().d(
          'UploadContentInteractor::execute(): FileSized $fileSize || maxMediaSize $maxMediaSize',
        );
        if (maxMediaSize != null && maxMediaSize < fileSize) {
          yield Left(
            FileTooBigMatrix(FileTooBigMatrixException(fileSize, maxMediaSize)),
          );
        }

        final response = await mediaApi.uploadFileMobile(
          fileInfo: contentFileInfo,
        );

        if (response.contentUri != null) {
          final contentUri = Uri.parse(response.contentUri!);
          yield Right(UploadContentSuccess(uri: contentUri));
        } else {
          yield Left(
            UploadContentFailed(exception: CannotUploadContentException()),
          );
        }
      } else {
        yield Left(
          UploadContentFailed(exception: CannotUploadContentException()),
        );
      }
    } catch (exception) {
      yield Left(UploadContentFailed(exception: exception));
    }
  }
}
