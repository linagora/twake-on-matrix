import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_media_key.freezed.dart';

/// A key that encrypts the media of one device of the call.
@freezed
abstract class CallMediaKey with _$CallMediaKey {
  const factory CallMediaKey({
    /// The media identity of the device, `<user id>:<device id>`.
    required String participantId,
    required int index,
    required List<int> key,
  }) = _CallMediaKey;
}
