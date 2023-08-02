
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/upload_file/upload_file_failed.dart';
import 'package:fluffychat/domain/app_state/upload_file/upload_file_loading.dart';
import 'package:fluffychat/domain/app_state/upload_file/upload_file_success.dart';
import 'package:fluffychat/domain/repository/upload_file_repository.dart';
import 'package:matrix/matrix.dart';

class UploadFileInteractor {
  final _uploadFileRepository = getIt.get<UploadFileRepository>();

  Stream<Either<Failure, Success>> execute({
    required FileInfo fileInfo,
  }) async* {
    yield const Right(UploadFileLoading());
    try {
      final contentUri = await _uploadFileRepository.uploadFile(fileInfo: fileInfo);
      yield Right(UploadFileSuccess(mxcUri: contentUri));
    } catch (e) {
      yield Left(UploadFileFailure(exception: e));
    }
  }
}