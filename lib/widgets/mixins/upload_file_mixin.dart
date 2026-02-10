import 'dart:async';
import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/file_not_exist_exception.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin UploadFileMixin<T extends StatefulWidget> on State<T> {
  final uploadManager = getIt.get<UploadManager>();

  late final ValueNotifier<UploadFileUIState> uploadFileStateNotifier;

  StreamSubscription<Either<Failure, Success>>? streamSubscription;

  Event get event;

  StreamSubscription<Either<Failure, Success>>?
  _trySetupUploadStreamSubcription() => streamSubscription = uploadManager
      .getUploadStateStream(event.eventId)
      ?.listen(setupUploadProcess);

  void setupUploadProcess(Either<Failure, Success> state) {
    state.fold(
      (failure) {
        Logs().e('UploadFileMixin::setupUploadProcess(): Failure $failure');
        if (failure is UploadFileFailedState &&
            failure.exception is CancelUploadException) {
          return;
        }
        if (failure is UploadFileFailedState &&
            failure.exception is FileNotExistException) {
          if (mounted) {
            TwakeSnackBar.show(context, L10n.of(context)!.fileNoLongerExists);
          }
        }
        uploadFileStateNotifier.value = const UploadFileFailedUIState();
      },
      (success) {
        Logs().d('UploadFileMixin::setupUploadProcess(): Success $success');
        if (success is UploadingFileState) {
          if (!success.isThumbnail) {
            uploadFileStateNotifier.value = UploadingFileUIState(
              receive: success.receive,
              total: success.total,
            );
          }
        } else if (success is UploadFileSuccessState) {
          uploadFileStateNotifier.value = const UploadFileSuccessUIState();
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (event.status == EventStatus.error) {
      uploadFileStateNotifier = ValueNotifier(const UploadFileFailedUIState());
    } else {
      uploadFileStateNotifier = ValueNotifier(const UploadFileUISateInitial());
    }
    _trySetupUploadStreamSubcription();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    uploadFileStateNotifier.dispose();
    super.dispose();
  }
}
