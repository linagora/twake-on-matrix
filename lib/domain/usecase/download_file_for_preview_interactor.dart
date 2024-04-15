import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_failure.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_loading.dart';
import 'package:fluffychat/domain/app_state/preview_file/download_file_for_preview_success.dart';
import 'package:fluffychat/domain/model/download_file/download_file_for_preview_response.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

class DownloadFileForPreviewInteractor {
  Stream<Either<Failure, Success>> execute({
    required Event event,
    required String tempDirPath,
    bool getThumbnail = false,
    Future<Uint8List> Function(Uri)? downloadCallback,
  }) async* {
    yield const Right(DownloadFileForPreviewLoading());
    try {
      final matrixFile = await event.downloadAndDecryptAttachment(
        downloadCallback: downloadCallback,
        getThumbnail: getThumbnail,
      );
      final tempFile = File('$tempDirPath/${event.filename}');
      tempFile.createSync(recursive: true);
      if (matrixFile.bytes == null) {
        yield const Left(
          DownloadFileForPreviewFailure(exception: 'Empty file'),
        );
      }
      tempFile.writeAsBytesSync(matrixFile.bytes!);
      Logs().d(
        'DownloadFileForPreviewInteractor::execute(): ${tempFile.path}, mimeType: ${lookupMimeType(tempFile.path)}',
      );
      yield Right(
        DownloadFileForPreviewSuccess(
          downloadFileForPreviewResponse: DownloadFileForPreviewResponse(
            filePath: tempFile.path,
            mimeType: lookupMimeType(tempFile.path),
          ),
        ),
      );
    } catch (e) {
      yield Left(DownloadFileForPreviewFailure(exception: e));
    }
  }
}
