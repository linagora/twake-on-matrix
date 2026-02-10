import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/presentation/enum/chat/audio_type_enum.dart';
import 'package:fluffychat/utils/localized_camera_picker_text_delegate.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

typedef OnSendPhotosTap = void Function()?;

mixin CommonMediaPickerMixin {
  static const _audioAccessDeniedCode = 'AudioAccessDeniedWithoutPrompt';

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  Future<PermissionStatus?>? getCurrentMediaPermission(BuildContext context) {
    return _permissionHandlerService.requestPermissionForMediaActions(context);
  }

  Future<PermissionStatus>? getCurrentCameraPermission() {
    return _permissionHandlerService.requestPermissionForCameraActions();
  }

  Future<PermissionStatus>? getCurrentMicroPermission({
    required BuildContext context,
    required AudioTypeEnum audioTypeEnum,
  }) {
    return _permissionHandlerService.requestPermissionForMicroActions(
      audioTypeEnum: audioTypeEnum,
      context: context,
    );
  }

  void goToSettings(BuildContext context, {bool isMicrophone = false}) {
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
            style: Theme.of(context).textTheme.bodyMedium,
            children: <TextSpan>[
              TextSpan(
                text: ' ${L10n.of(context)!.twake}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
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

  void _onError({required BuildContext context, required Object error}) {
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
              textDelegate: getTextDelegateForLocale(context),
              enableAudio: false,
              onError: (e, a) => _onError(context: context, error: e),
            )
          : CameraPickerConfig(
              textDelegate: getTextDelegateForLocale(context),
              enableRecording: true,
              onError: (e, a) => _onError(context: context, error: e),
            ),
    );
  }

  CameraPickerTextDelegate getTextDelegateForLocale(BuildContext context) {
    switch (LocalizationService.currentLocale.value.languageCode) {
      case 'ru':
      case 'fr':
        return LocalizedCameraPickerTextDelegate(
          context,
          LocalizationService.currentLocale.value.languageCode,
        );
      default:
        return cameraPickerTextDelegateFromLocale(
          LocalizationService.currentLocale.value,
        );
    }
  }

  void goToMicroSettings(BuildContext context) {
    showDialog<bool?>(
      context: context,
      useRootNavigator: false,
      builder: (c) => PermissionDialog(
        permission: Permission.microphone,
        explainTextRequestPermission: RichText(
          text: TextSpan(
            text: L10n.of(context)!.tapToAllowAccessToYourMicrophone,
            style: Theme.of(context).textTheme.bodyMedium,
            children: <TextSpan>[
              TextSpan(
                text: ' ${L10n.of(context)!.twake}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.keyboard_voice_outlined),
        onAcceptButton: () {
          Navigator.of(context).pop();
          PermissionHandlerService().goToSettingsForPermissionActions();
        },
      ),
    );
  }
}
