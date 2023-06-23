import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  static final PermissionHandlerService _instance = PermissionHandlerService._internal();

  factory PermissionHandlerService() {
    return _instance;
  }

  PermissionHandlerService._internal();


  Future<PermissionStatus>? requestPermissionForPhotoActions() {
    if (Platform.isIOS) {
      return _handlePhotosPermissionIOSAction();
    } else if (Platform.isAndroid) {
      return _handlePhotosPermissionAndroidAction();
    } else {
      return null;
    }
  }

  Future<PermissionStatus> requestPermissionForCameraActions() async {
    final currentStatus = await Permission.camera.status;
    if (currentStatus == PermissionStatus.denied || currentStatus == PermissionStatus.permanentlyDenied) {
      final newStatus = await Permission.camera.request();
      return newStatus.isGranted ? PermissionStatus.granted : newStatus;
    } else {
      return currentStatus;
    }
  }

  Future<PermissionStatus> _handlePhotosPermissionIOSAction() async {
    final currentStatus = await Permission.photos.status;
    return _handlePhotoPermission(currentStatus);
  }

  Future<PermissionStatus> _handlePhotosPermissionAndroidAction() async {
    final currentStatus = await Permission.storage.status;
    return _handlePhotoPermission(currentStatus);
  }

  Future<PermissionStatus> _handlePhotoPermission(PermissionStatus currentStatus) async {
    switch (currentStatus) {
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.denied:
        final newStatus = Platform.isIOS
          ? await Permission.photos.request()
          : await Permission.storage.request();
        return newStatus.isGranted ? PermissionStatus.granted : newStatus;

      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
      case PermissionStatus.restricted:
        return currentStatus;
    }
  }

  void goToSettingsForPermissionActions() {
    openAppSettings();
  }
}