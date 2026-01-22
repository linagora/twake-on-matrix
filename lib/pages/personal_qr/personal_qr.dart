import 'dart:io';
import 'dart:ui' as ui;

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/personal_qr/personal_qr_view.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class PersonalQr extends StatefulWidget {
  const PersonalQr({super.key});

  @override
  PersonalQrController createState() => PersonalQrController();
}

class PersonalQrController extends State<PersonalQr> {
  final GlobalKey qrKey = GlobalKey();

  /// Shares the QR code as an image file
  Future<void> shareQrCode(BuildContext context) async {
    File? tempFile;
    try {
      final l10n = L10n.of(context)!;

      final imageBytes = await _captureQrImage(context, l10n);
      if (imageBytes == null) {
        return;
      }

      tempFile = await _createTempFile(imageBytes);

      final shareResult = await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: l10n.shareQrCode);

      // Clean up immediately if share was dismissed/completed
      // For platforms that don't return result, fall back to delayed cleanup
      if (shareResult.status == ShareResultStatus.dismissed ||
          shareResult.status == ShareResultStatus.success) {
        await _cleanupTempFile(tempFile);
      } else {
        // Fallback for platforms that return unavailable status
        _scheduleDelayedCleanup(tempFile);
      }
    } catch (e, s) {
      Logs().e('PersonalQr::shareQrCode():: error', e, s);
      // Ensure cleanup even on error
      if (tempFile != null) {
        await _cleanupTempFile(tempFile);
      }
      if (!mounted) return;
      TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
    }
  }

  /// Downloads the QR code as an image and saves it to the gallery
  Future<void> downloadQrCode(BuildContext context) async {
    File? tempFile;
    try {
      final l10n = L10n.of(context)!;

      final permissionGranted = await _requestStoragePermissions();
      if (!permissionGranted) {
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (_) {
            return PermissionDialog(
              icon: const Icon(Icons.photo),
              permission: Permission.photos,
              explainTextRequestPermission: Text(
                L10n.of(
                  context,
                )!.explainPermissionToGallery(AppConfig.applicationName),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onAcceptButton: () =>
                  PermissionHandlerService().goToSettingsForPermissionActions(),
            );
          },
        );
        return;
      }

      final imageBytes = await _captureQrImage(context, l10n);
      if (imageBytes == null) {
        return;
      }

      tempFile = await _createTempFile(imageBytes);
      await Gal.putImage(tempFile.path);
      await _cleanupTempFile(tempFile);

      if (!mounted) return;
      TwakeSnackBar.show(context, l10n.fileSavedToGallery);
    } catch (e, s) {
      Logs().e('PersonalQr::downloadQrCode():: error', e, s);
      // Ensure cleanup even on error
      if (tempFile != null) {
        await _cleanupTempFile(tempFile);
      }
      if (!mounted) return;
      TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
    }
  }

  /// Creates a temporary file with the given image bytes
  Future<File> _createTempFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path.join(tempDir.path, 'qr_code_$timestamp.png');
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return file;
  }

  /// Safely deletes a temporary file
  Future<void> _cleanupTempFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e, s) {
      Logs().e('PersonalQr::_cleanupTempFile():: error', e, s);
    }
  }

  /// Schedules delayed cleanup for platforms that don't return share status
  void _scheduleDelayedCleanup(File file) {
    Future.delayed(const Duration(seconds: 2), () {
      _cleanupTempFile(file);
    });
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
    final androidVersion = await permissionHandlerService
        .getCurrentAndroidVersion();
    if (androidVersion >= 33) {
      // Android 13+: use gal's built-in permission handling or request photos permission
      return await Gal.requestAccess(toAlbum: true);
    } else if (androidVersion >= 30) {
      final permission = await Permission.photos.request();
      return permission.isGranted;
    } else if (await permissionHandlerService
        .isUserHaveToRequestStoragePermissionAndroid()) {
      final permission = await Permission.storage.request();
      return permission.isGranted;
    }
    return true;
  }

  /// Requests photo permission for iOS
  Future<bool> _requestIosPhotoPermission() async {
    final permissionHandlerService = PermissionHandlerService();
    final permissionStatus = await permissionHandlerService
        .requestPhotoAddOnlyPermissionIOS();
    return permissionStatus.isGranted;
  }

  Future<Uint8List?> _overlayWidgetOnAsset(
    ByteData foregroundData,
    String assetPath,
  ) async {
    try {
      final ByteData assetData = await rootBundle.load(assetPath);
      final Uint8List assetBytes = assetData.buffer.asUint8List();
      final img.Image? background = img.decodePng(assetBytes);

      final foregroundBytes = foregroundData.buffer.asUint8List();
      final img.Image? foreground = img.decodePng(foregroundBytes);

      if (background == null || foreground == null) return foregroundBytes;

      img.compositeImage(background, foreground, center: true);

      return Uint8List.fromList(img.encodePng(background));
    } catch (e) {
      Logs().e(
        'PersonalQrController::_overlayWidgetOnAsset:: Cannot embed background to personal QR',
        e,
      );
      return foregroundData.buffer.asUint8List();
    }
  }

  /// Captures the QR code widget as a PNG image
  Future<Uint8List?> _captureQrImage(BuildContext context, L10n l10n) async {
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
      if (!mounted) return null;
      TwakeSnackBar.show(context, l10n.oopsSomethingWentWrong);
      return null;
    }

    return await _overlayWidgetOnAsset(
      byteData,
      ImagePaths.personalQrBackground,
    );
  }

  @override
  Widget build(BuildContext context) => PersonalQrView(this);
}
