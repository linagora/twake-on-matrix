import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

typedef OnSendPhotosTap = void Function()?;

mixin CommonMediaPickerMixin {
  static const _audioAccessDeniedCode = 'AudioAccessDeniedWithoutPrompt';

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  Future<PermissionStatus?>? getCurrentMediaPermission() {
    return _permissionHandlerService.requestPermissionForMediaActions();
  }

  Future<PermissionStatus>? getCurrentCameraPermission() {
    return _permissionHandlerService.requestPermissionForCameraActions();
  }

  Future<PermissionStatus>? getCurrentMicroPermission() {
    return _permissionHandlerService.requestPermissionForMircoActions();
  }

  void goToSettings(
    BuildContext context, {
    bool isMicrophone = false,
  }) {
    showDialog<bool?>(
      context: context,
      useRootNavigator: false,
      builder: (c) => PermissionDialog(
        permission: Permission.camera,
        explainTextRequestPermission: RichText(
          text: TextSpan(
            text: isMicrophone
                ? L10n.of(context)!.tapToAllowAccessToYourMicrophone
                : L10n.of(context)!.tapToAllowAccessToYourCamera,
            style: Theme.of(context).textTheme.titleSmall,
            children: <TextSpan>[
              TextSpan(
                text: ' ${L10n.of(context)!.twake}.',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.camera_alt),
        onAcceptButton: () {
          Navigator.of(context).pop();
          PermissionHandlerService().goToSettingsForPermissionActions();
        },
      ),
    );
  }

  void _onError({
    required BuildContext context,
    required Object error,
  }) {
    if (error is! CameraException) return;
    Logs().e("CommonMediaPickerMixin:: _onError", error.code);
    if (error.code.contains(_audioAccessDeniedCode)) {
      Navigator.of(context).maybePop();
    }
  }

  Future<AssetEntity?> pickMediaFromCameraAction({
    required BuildContext context,
    bool onlyImage = false,
  }) async {
    Navigator.pop(context);
    return await CameraPicker.pickFromCamera(
      context,
      pickerConfig: onlyImage
          ? CameraPickerConfig(
              enableAudio: false,
              onError: (e, a) => _onError(context: context, error: e),
            )
          : CameraPickerConfig(
              enableRecording: true,
              onError: (e, a) => _onError(context: context, error: e),
            ),
      locale: View.of(context).platformDispatcher.locale,
    );
  }
}
