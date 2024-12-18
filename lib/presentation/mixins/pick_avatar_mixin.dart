import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/model/extensions/platform_file/platform_file_extension.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/int_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin PickAvatarMixin {
  final ValueNotifierCustom<Either<Failure, Success>> pickAvatarUIState =
      ValueNotifierCustom<Either<Failure, Success>>(
    Right(GetAvatarInitialUIState()),
  );

  void handlePickAvatarOnWeb(FilePickerResult filePickerResult) {
    final matrixFile = filePickerResult.files.single.toMatrixFileOnWeb();
    Logs().d(
      'PickAvatarMixin::handlePickAvatarOnWeb(): AvatarWebNotifier - ${matrixFile.size}',
    );
    if (matrixFile.size > AppConfig.defaultMaxUploadAvtarSizeInBytes) {
      pickAvatarUIState.value = const Left<Failure, Success>(
        GetAvatarBigSizeUIStateFailure(),
      );
      return;
    }
    pickAvatarUIState.value = Right<Failure, Success>(
      GetAvatarOnWebUIStateSuccess(
        matrixFile: matrixFile,
      ),
    );
  }

  void pickAvatarImageOnWeb() async {
    pickAvatarUIState.value = Right<Failure, Success>(
      PickingAvatarUIState(),
    );
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConfig.allowedExtensionsSupportedAvatar,
      withReadStream: true,
    );
    if (result == null || result.files.single.readStream == null) {
      return;
    } else {
      handlePickAvatarOnWeb(result);
    }
  }

  void listenToPickAvatarUIState(BuildContext context) {
    pickAvatarUIState.addListener(() {
      pickAvatarUIState.value.fold(
        (failure) {
          Logs().e('PickAvatarMixin::_listenToPickAvatarUIState(): $failure');
          if (failure is GetAvatarBigSizeUIStateFailure) {
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.fileTooBig(
                AppConfig.defaultMaxUploadAvtarSizeInBytes.bytesToMBInt(),
              ),
            );
          }
        },
        (success) {
          Logs().d('PickAvatarMixin::_listenToPickAvatarUIState(): $success');
        },
      );
    });
  }

  void disposePickAvatarMixin() {
    pickAvatarUIState.dispose();
  }
}
