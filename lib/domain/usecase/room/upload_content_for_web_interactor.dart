import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:matrix/matrix.dart';

class UploadContentInBytesInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required MatrixFile matrixFile,
  }) async* {
    try {
      yield Right(UploadContentLoading());
      final mediaConfig = await matrixClient.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      final fileSize = matrixFile.size;
      Logs().d(
        'UploadContentWebInteractor::execute(): FileSize $fileSize || maxMediaSize $maxMediaSize',
      );
      if (maxMediaSize != null && maxMediaSize < fileSize) {
        yield Left(
          FileTooBigMatrix(FileTooBigMatrixException(fileSize, maxMediaSize)),
        );
        return;
      }

      final uri = await matrixClient.uploadContent(
        matrixFile.bytes,
        filename: matrixFile.name,
        contentType: matrixFile.mimeType,
      );
      yield Right(UploadContentSuccess(uri: uri));
    } catch (exception) {
      yield Left(UploadContentFailed(exception: exception));
    }
  }
}
