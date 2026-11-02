import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_space.freezed.dart';

/// The space a user asks for. A space is never encrypted.
@freezed
abstract class NewSpace with _$NewSpace {
  const factory NewSpace({
    required String name,
    @Default('') String topic,
    @Default(false) bool isPublic,

    /// Sets `m.federate: false` on a public space; cannot be changed later.
    @Default(false) bool isServerLimited,
    String? parentSpaceId,
    String? urlAvatar,
  }) = _NewSpace;
}
