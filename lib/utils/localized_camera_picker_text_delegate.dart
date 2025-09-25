import 'package:flutter/material.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class LocalizedCameraPickerTextDelegate extends CameraPickerTextDelegate {
  final BuildContext context;
  final String language;
  const LocalizedCameraPickerTextDelegate(this.context, this.language);

  @override
  String get languageCode => language;

  @override
  String get confirm => L10n.of(context)!.confirm;

  @override
  String get shootingTips => L10n.of(context)!.shootingTips;

  @override
  String get shootingWithRecordingTips =>
      L10n.of(context)!.shootingWithRecordingTips;

  @override
  String get shootingOnlyRecordingTips =>
      L10n.of(context)!.shootingOnlyRecordingTips;

  @override
  String get shootingTapRecordingTips =>
      L10n.of(context)!.shootingTapRecordingTips;

  @override
  String get loadFailed => L10n.of(context)!.loadFailed;

  @override
  String get loading => L10n.of(context)!.loading;

  @override
  String get saving => L10n.of(context)!.saving;

  @override
  String get sActionManuallyFocusHint =>
      L10n.of(context)!.sActionManuallyFocusHint;

  @override
  String get sActionPreviewHint => L10n.of(context)!.sActionPreviewHint;

  @override
  String get sActionRecordHint => L10n.of(context)!.sActionRecordHint;

  @override
  String get sActionShootHint => L10n.of(context)!.sActionShootHint;

  @override
  String get sActionShootingButtonTooltip =>
      L10n.of(context)!.sActionShootingButtonTooltip;

  @override
  String get sActionStopRecordingHint =>
      L10n.of(context)!.sActionStopRecordingHint;

  @override
  String sCameraLensDirectionLabel(CameraLensDirection value) =>
      L10n.of(context)!.sCameraLensDirectionLabel(value.name);

  @override
  String? sCameraPreviewLabel(CameraLensDirection? value) {
    if (value == null) {
      return null;
    }
    return L10n.of(context)!.sCameraPreviewLabel(value.name);
  }

  @override
  String sFlashModeLabel(FlashMode mode) =>
      L10n.of(context)!.sFlashModeLabel(mode.name);

  @override
  String sSwitchCameraLensDirectionLabel(CameraLensDirection value) =>
      L10n.of(context)!.sSwitchCameraLensDirectionLabel(value.name);
}
