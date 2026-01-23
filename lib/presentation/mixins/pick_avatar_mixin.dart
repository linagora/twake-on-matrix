import 'package:byte_converter/byte_converter.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

mixin PickAvatarMixin {
  final ValueNotifierCustom<Either<Failure, Success>> pickAvatarUIState =
      ValueNotifierCustom<Either<Failure, Success>>(
    Right(GetAvatarInitialUIState()),
  );

  Future<void> handlePickAvatarOnWeb(FilePickerResult filePickerResult) async {
    final file = filePickerResult.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      pickAvatarUIState.value = const Left<Failure, Success>(
        GetAvatarUIStateFailure(),
      );
      return;
    }
    final matrixFile = MatrixFile.fromMimeType(
      bytes: bytes,
      name: file.name,
      mimeType: MimeTypeUitls.instance.getTwakeMimeType(file.name),
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
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
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
                AppConfig.defaultMaxUploadAvtarSizeInBytes.bytes.megaBytes
                    .toInt(),
              ),
            );
          } else if (failure is GetAvatarUIStateFailure) {
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.oopsSomethingWentWrong,
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
