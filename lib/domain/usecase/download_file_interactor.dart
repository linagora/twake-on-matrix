import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/download_file/download_file_failed.dart';
import 'package:fluffychat/domain/app_state/download_file/download_file_loading.dart';
import 'package:fluffychat/domain/app_state/download_file/download_file_success.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class DownloadFileInteractor {
  Stream<Either<Failure, Success>> execute(
    Event event,
    BuildContext context,
  ) async* {
    yield const Right(DownloadFileLoading());
    try {
      await event.saveFile(context);

      yield const Right(DownloadFileSuccess());
    } catch (e) {
      yield Left(DownloadFileFailed(exception: e));
    }
  }
}
