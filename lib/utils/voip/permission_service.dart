import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  static final PermissionHandlerService _instance = PermissionHandlerService._internal();

  factory PermissionHandlerService() {
    return _instance;
  }

  PermissionHandlerService._internal();


  Future<PermissionStatus> requestPermissionForPhotoActions() {
    if (Platform.isIOS) {
      return _handlePhotosPermissionIOSAction();
    } else {
      return _handlePhotosPermissionAndroidAction();
    }
  }

  Future<PermissionStatus> _handlePhotosPermissionIOSAction() async {
    final currentStatus = await Permission.photos.status;
    return _handlePermission(currentStatus);
  }

  Future<PermissionStatus> _handlePhotosPermissionAndroidAction() async {
    final currentStatus = await Permission.storage.status;
    return _handlePermission(currentStatus);
  }


  Future<PermissionStatus> _handlePermission(PermissionStatus currentStatus) async {
    switch (currentStatus) {
      case PermissionStatus.denied:
      case PermissionStatus.limited:
        final newStatus = Platform.isIOS
          ? await Permission.mediaLibrary.request()
          : await Permission.storage.request();
        return newStatus.isGranted ? PermissionStatus.granted : newStatus;

      case PermissionStatus.granted:
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        return currentStatus;
    }
  }

  void goToSettingsForPermissionActions() {
    openAppSettings();
  }
}