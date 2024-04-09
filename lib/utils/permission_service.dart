import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  static final PermissionHandlerService _instance =
      PermissionHandlerService._internal();

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  factory PermissionHandlerService() {
    return _instance;
  }

  PermissionHandlerService._internal();

  Future<PermissionStatus?>? requestPermissionForMediaActions() async {
    if (Platform.isIOS) {
      return _handlePhotosPermissionIOSAction();
    } else if (Platform.isAndroid) {
      if (await _getCurrentAndroidVersion() >= 33) {
        return _handleMediaPickerPermissionAndroidHigher33Action();
      }
      return _handleMediaPermissionAndroidAction();
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

  Future<PermissionStatus> requestPermissionForMircoActions() async {
    final currentStatus = await Permission.microphone.status;
    if (currentStatus == PermissionStatus.denied ||
        currentStatus == PermissionStatus.permanentlyDenied) {
      return await Permission.microphone.request();
    } else {
      return currentStatus;
    }
  }

  Future<PermissionStatus> _handlePhotosPermissionIOSAction() async {
    final currentStatus = await Permission.photos.status;
    return _handlePhotoPermission(currentStatus);
  }

  Future<PermissionStatus> _handleMediaPermissionAndroidAction() async {
    final currentStatus = await Permission.storage.status;
    return _handlePhotoPermission(currentStatus);
  }

  Future<PermissionStatus>
      _handleMediaPickerPermissionAndroidHigher33Action() async {
    PermissionStatus? photoPermission = await Permission.photos.status;
    if (photoPermission == PermissionStatus.denied) {
      photoPermission = await Permission.photos.request();
    }

    PermissionStatus? videosPermission = await Permission.videos.status;
    if (videosPermission == PermissionStatus.denied) {
      videosPermission = await Permission.videos.request();
    }

    if (photoPermission == PermissionStatus.granted ||
        videosPermission == PermissionStatus.granted) {
      return PermissionStatus.granted;
    }

    return PermissionStatus.denied;
  }

  Future<PermissionStatus> _handlePhotoPermission(
    PermissionStatus currentStatus,
  ) async {
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
    if (currentStatus == PermissionStatus.denied ||
        currentStatus == PermissionStatus.permanentlyDenied) {
      final newStatus = await Permission.contacts.request();
      return newStatus.isGranted ? PermissionStatus.granted : newStatus;
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
