import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/personal_qr/personal_qr_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PersonalQr extends StatefulWidget {
  const PersonalQr({super.key});

  @override
  PersonalQrController createState() => PersonalQrController();
}

class PersonalQrController extends State<PersonalQr> {
  final GlobalKey qrKey = GlobalKey();

  /// Downloads the QR code as an image and saves it to the gallery
  Future<void> downloadQrCode(BuildContext context) async {
    try {
      final l10n = L10n.of(context)!;

      final permissionGranted = await _requestStoragePermissions();
      if (!permissionGranted) {
        return;
      }

      final imageBytes = await _captureQrImage(context, l10n);
      if (imageBytes == null) {
        return;
      }

      await _saveImageToGallery(imageBytes);
      if (!mounted) return;
      TwakeSnackBar.show(context, l10n.fileSavedToGallery);
    } catch (e, s) {
      Logs().e('PersonalQr::downloadQrCode():: error', e, s);
      if (!mounted) return;
      TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
    }
  }

  /// Requests storage permissions based on platform
  Future<bool> _requestStoragePermissions() async {
    if (PlatformInfos.isAndroid) {
      return _requestAndroidStoragePermission();
    } else if (PlatformInfos.isIOS) {
      return _requestIosPhotoPermission();
    }
    return false;
  }

  /// Requests storage permission for Android
  Future<bool> _requestAndroidStoragePermission() async {
    final permissionHandlerService = PermissionHandlerService();
    if (await permissionHandlerService
        .isUserHaveToRequestStoragePermissionAndroid()) {
      final permission = await Permission.storage.request();
      return permission.isGranted;
    }
    return true;
  }

  /// Requests photo permission for iOS
  Future<bool> _requestIosPhotoPermission() async {
    final permissionHandlerService = PermissionHandlerService();
    final permissionStatus =
        await permissionHandlerService.requestPhotoAddOnlyPermissionIOS();
    return permissionStatus.isGranted;
  }

  /// Captures the QR code widget as a PNG image
  Future<Uint8List?> _captureQrImage(
    BuildContext context,
    L10n l10n,
  ) async {
    final boundary =
        qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      Logs().e('PersonalQr::_captureQrImage():: boundary is null');
      TwakeSnackBar.show(context, l10n.oopsSomethingWentWrong);
      return null;
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      Logs().e('PersonalQr::_captureQrImage():: byteData is null');
      TwakeSnackBar.show(context, l10n.oopsSomethingWentWrong);
      return null;
    }

    return byteData.buffer.asUint8List();
  }

  /// Saves the image bytes to the gallery
  Future<void> _saveImageToGallery(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/qr_code_$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    await Gal.putImage(file.path);
  }

  @override
  Widget build(BuildContext context) => PersonalQrView(this);
}
