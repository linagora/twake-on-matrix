import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_session.freezed.dart';

@freezed
abstract class DrivePickerSession with _$DrivePickerSession {
  const factory DrivePickerSession({
    required String id,
    required Uri url,
    String? client,
  }) = _DrivePickerSession;
}
