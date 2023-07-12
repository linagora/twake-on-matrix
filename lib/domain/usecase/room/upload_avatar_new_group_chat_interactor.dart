
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/upload_avatar_new_group_chat_state.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';

class UploadAvatarNewGroupChatInteractor {
  Stream<Either<Failure, Success>> execute({
    required Client matrixClient,
    required Uint8List file,
    String? fileName,
    String? contentType,
  }) async* {
    try {
      yield Right(UploadAvatarNewGroupChatLoading());
      final mediaConfig = await matrixClient.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      Logs().d('SendImage::sendImageFileEvent(): FileSized ${file.lengthInBytes} || maxMediaSize $maxMediaSize');
      if (maxMediaSize != null && maxMediaSize < file.lengthInBytes) {
        yield Left(FileTooBigMatrix(FileTooBigMatrixException(file.lengthInBytes, maxMediaSize)));
      }
      final uri = await matrixClient.uploadContent(
        file,
        filename: fileName,
        contentType: contentType,
      );
      yield Right(UploadAvatarNewGroupChatSuccess(uri: uri));
    } catch (exception) {
      yield Left(UploadAvatarNewGroupChatFailed(exception: exception));
    }
  }
}