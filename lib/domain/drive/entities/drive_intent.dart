import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_intent.freezed.dart';

/// A PICK intent Drive created for this session: the page to load and the
/// client name it expects the messages to come from.
@freezed
abstract class DriveIntent with _$DriveIntent {
  const factory DriveIntent({
    required String intentId,
    required Uri intentUrl,
    String? client,
  }) = _DriveIntent;
}
