import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/send_file_dialog/generate_thumbnails_media_state.dart';
import 'package:fluffychat/domain/repository/server_config_repository.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:matrix/matrix.dart';

typedef OnConvertReadStreamToBytesDone = void Function(
  MatrixFile oldFile,
  MatrixFile newFile,
);

class GenerateThumbnailsMediaInteractor {
  ServerConfigRepository get _serverConfigRepository =>
      getIt.get<ServerConfigRepository>();

  Stream<Either<Failure, Success>> execute({
    required Room room,
    required List<MatrixFile> files,
  }) async* {
    try {
      final serverConfig = await _serverConfigRepository.getServerConfig();
      if (serverConfig.mUploadSize == null) {
        yield const Left(GenerateThumbnailsMediaFailure('mUploadSize is null'));
      }
      yield Right(
        GenerateThumbnailsMediaInitial(
          maxUploadFileSize: serverConfig.mUploadSize!,
        ),
      );

      final filesHaveThumbnail = files.whereType<MatrixImageFile>().toList();
      for (final file in filesHaveThumbnail) {
        MatrixImageFile? thumbnail;
        yield Right(
          ConvertReadStreamToBytesSuccess(oldFile: file, newFile: file),
        );
        thumbnail = await room.generateThumbnail(file);
        if (thumbnail != null) {
          yield Right(
            GenerateThumbnailsMediaSuccess(
              file: file,
              thumbnail: thumbnail,
            ),
          );
        } else {
          yield const Left(GenerateThumbnailsMediaFailure('thumbnail is null'));
        }
      }
    } catch (e) {
      Logs().e('GenerateThumbnailsMediaInteractor::execute', e);
      yield Left(GenerateThumbnailsMediaFailure(e));
    }
  }
}
