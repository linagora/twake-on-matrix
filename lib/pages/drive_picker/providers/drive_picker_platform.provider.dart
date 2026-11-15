import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_drive_picker/ui.dart' show DrivePickerPlatform;

part 'drive_picker_platform.provider.g.dart';

/// The WebView the picker runs in. A provider so a test puts a fake in its
/// place: the real one needs a device.
@Riverpod(keepAlive: true)
DrivePickerPlatform drivePickerPlatform(Ref ref) => DrivePickerPlatform.current;
