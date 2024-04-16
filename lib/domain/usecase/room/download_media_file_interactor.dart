import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/download/download_file_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:matrix/matrix.dart';

class DownloadMediaFileInteractor {
  DownloadMediaFileInteractor();

  Stream<Either<Failure, Success>> execute({
    required Event event,
    bool getThumbnail = false,
  }) async* {
    try {
      final fileInfo = await event.getFileInfo(
        getThumbnail: getThumbnail,
      );
      if (fileInfo == null) {
        yield const Left(
          DownloadMediaFileFailure(exception: 'FileInfo is null'),
        );
        return;
      }
      yield Right(DownloadMediaFileSuccess(filePath: fileInfo.filePath));
    } catch (error) {
      Logs().e('DownloadMediaFileInteractor: execute(): $error');
      yield Left(DownloadMediaFileFailure(exception: error));
    }
  }
}
