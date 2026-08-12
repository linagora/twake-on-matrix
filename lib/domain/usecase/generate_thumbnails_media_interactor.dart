import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/send_file_dialog/generate_thumbnails_media_state.dart';
import 'package:twake_chat/domain/repository/server_config_repository.dart';
import 'package:twake_chat/presentation/extensions/media_thumbnail_extension.dart';
import 'package:matrix/matrix.dart';

typedef OnConvertReadStreamToBytesDone =
    void Function(MatrixFile oldFile, MatrixFile newFile);

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
        thumbnail = await room.generateThumbnail(file);
        if (thumbnail != null) {
          yield Right(
            GenerateThumbnailsMediaSuccess(file: file, thumbnail: thumbnail),
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
