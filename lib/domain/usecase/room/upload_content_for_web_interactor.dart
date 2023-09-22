import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/upload_content_state.dart';
import 'package:fluffychat/domain/exception/room/can_not_upload_content_exception.dart';
import 'package:fluffychat/domain/repository/media/media_repository.dart';
import 'package:matrix/matrix.dart';

class UploadContentForWebInteractor {
  final MediaRepository _mediaRepository;

  UploadContentForWebInteractor(this._mediaRepository);

  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required FilePickerResult filePickerResult,
  }) async* {
    try {
      yield Right(UploadContentLoading());
      if (filePickerResult.files.single.bytes != null) {
        final mediaConfig = await matrixClient.getConfig();
        final maxMediaSize = mediaConfig.mUploadSize;
        final fileSize = filePickerResult.files.single.size;
        final mimeType = MatrixFile.fromMimeType(
          bytes: filePickerResult.files.single.bytes,
          name: filePickerResult.files.single.name,
          filePath: '',
        ).mimeType;
        Logs().d(
          'UploadContentWebInteractor::execute(): FileSized $fileSize || maxMediaSize $maxMediaSize',
        );
        if (maxMediaSize != null && maxMediaSize < fileSize) {
          yield Left(
            FileTooBigMatrix(
              FileTooBigMatrixException(fileSize, maxMediaSize),
            ),
          );
        }

        final response = await _mediaRepository.uploadContentForWeb(
          filePickerResult.files.single.bytes!,
          contentType: mimeType,
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
