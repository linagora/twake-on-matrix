import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  static final PermissionHandlerService _instance =
      PermissionHandlerService._internal();

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  factory PermissionHandlerService() {
    return _instance;
  }

  PermissionHandlerService._internal();

  Future<PermissionStatus?>? requestPermissionForMediaActions(
    BuildContext context,
  ) async {
    if (Platform.isIOS) {
      return _handlePhotosPermissionIOSAction(context);
    } else if (Platform.isAndroid) {
      if (await _getCurrentAndroidVersion() >= 33) {
        return _handleMediaPickerPermissionAndroidHigher33Action(context);
      }
      return _handleMediaPermissionAndroidAction(context);
    } else {
      return null;
    }
  }

  Future<int> _getCurrentAndroidVersion() async {
    return (await _deviceInfoPlugin.androidInfo).version.sdkInt;
  }

  Future<bool> noNeedStoragePermission() async {
    return Platform.isAndroid && (await _getCurrentAndroidVersion() >= 33);
  }

  Future<PermissionStatus> requestPermissionForCameraActions() async {
    final currentStatus = await Permission.camera.status;
    if (currentStatus == PermissionStatus.denied ||
        currentStatus == PermissionStatus.permanentlyDenied) {
      return await Permission.camera.request();
    } else {
      return currentStatus;
    }
  }

  Future<PermissionStatus> requestPermissionForMicroActions() async {
    final currentStatus = await Permission.microphone.status;
    if (currentStatus == PermissionStatus.denied ||
        currentStatus == PermissionStatus.permanentlyDenied) {
      return await Permission.microphone.request();
    } else {
      return currentStatus;
    }
  }

  Future<PermissionStatus> _handlePhotosPermissionIOSAction(
    BuildContext context,
  ) async {
    final currentStatus = await Permission.photos.status;
    return _handlePhotoPermission(
      currentStatus: currentStatus,
      context: context,
    );
  }

  Future<PermissionStatus> _handleMediaPermissionAndroidAction(
    BuildContext context,
  ) async {
    final currentStatus = await Permission.storage.status;
    return _handlePhotoPermission(
      currentStatus: currentStatus,
      context: context,
    );
  }

  Future<PermissionStatus> _handleMediaPickerPermissionAndroidHigher33Action(
    BuildContext context,
  ) async {
    if (await Permission.photos.status == PermissionStatus.denied) {
      final result = await showDialog<bool>(
        useRootNavigator: false,
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PermissionDialog(
            icon: const Icon(Icons.photo),
            permission: Permission.photos,
            explainTextRequestPermission: Text(
              L10n.of(context)!.explainPermissionToAccessPhotos,
            ),
            onAcceptButton: () async {
              Navigator.of(dialogContext).pop(true);
            },
          );
        },
      );

      if (result != null && result) {
        final newStatus = await Permission.photos.request();
        return newStatus;
      }
    }

    if (await Permission.videos.status == PermissionStatus.denied) {
      final result = await showDialog<bool>(
        useRootNavigator: false,
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PermissionDialog(
            icon: const Icon(Icons.video_camera_back_outlined),
            permission: Permission.videos,
            explainTextRequestPermission: Text(
              L10n.of(context)!.explainPermissionToAccessVideos,
            ),
            onAcceptButton: () async {
              Navigator.of(dialogContext).pop(true);
            },
          );
        },
      );
      if (result != null && result) {
        final newStatus = await Permission.videos.request();
        return newStatus;
      }
    }

    final photoPermission = await Permission.photos.status;
    final videosPermission = await Permission.videos.status;

    if (photoPermission == PermissionStatus.granted ||
        videosPermission == PermissionStatus.granted) {
      return PermissionStatus.granted;
    }

    return PermissionStatus.denied;
  }

  Future<PermissionStatus> _handlePhotoPermission({
    required PermissionStatus currentStatus,
    required BuildContext context,
  }) async {
    switch (currentStatus) {
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.denied:
        final result = await showDialog<bool>(
          useRootNavigator: false,
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return PermissionDialog(
              icon: const Icon(Icons.photo),
              permission:
                  Platform.isIOS ? Permission.photos : Permission.storage,
              explainTextRequestPermission: Text(
                L10n.of(context)!.explainPermissionToAccessMedias,
              ),
              onAcceptButton: () async {
                Navigator.of(dialogContext).pop(true);
              },
            );
          },
        );
        if (result != null && result) {
          final newStatus = Platform.isIOS
              ? await Permission.photos.request()
              : await Permission.storage.request();

          return newStatus.isGranted ? PermissionStatus.granted : newStatus;
        } else {
          return currentStatus;
        }

      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
      case PermissionStatus.restricted:
        return currentStatus;
    }
  }

  Future<bool> get hasStoragePermission async {
    return await Permission.storage.isGranted;
  }

  Future<PermissionStatus> get storagePermissionStatus async {
    return await Permission.storage.status;
  }

  Future<PermissionStatus> get contactsPermissionStatus async {
    return await Permission.contacts.status;
  }

  Future<PermissionStatus> requestContactsPermissionActions() async {
    final currentStatus = await contactsPermissionStatus;
    if (currentStatus == PermissionStatus.denied) {
      final newStatus = await Permission.contacts.request();
      return newStatus.isGranted ? PermissionStatus.granted : newStatus;
    } else if (currentStatus == PermissionStatus.permanentlyDenied) {
      goToSettingsForPermissionActions();
      return await contactsPermissionStatus;
    } else {
      return currentStatus;
    }
  }

  Future<bool> isUserHaveToRequestStoragePermissionAndroid() async {
    return await _getCurrentAndroidVersion() <= 29 &&
        !(await Permission.storage.isGranted);
  }

  Future<PermissionStatus> requestPhotoAddOnlyPermissionIOS() async {
    return await Permission.photosAddOnly.request();
  }

  void goToSettingsForPermissionActions() {
    openAppSettings();
  }
}
