import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_space.freezed.dart';

/// The space a user asks for. A space is never encrypted.
@freezed
abstract class NewSpace with _$NewSpace {
  const factory NewSpace({
    required String name,
    @Default('') String topic,
    @Default(false) bool isPublic,

    /// The homeserver keeps public rooms on itself with `m.room.server_acl`,
    /// so a public space does not need `m.federate: false`.
    @Default(false) bool isServerAclEnabled,
    String? parentSpaceId,
    String? urlAvatar,
  }) = _NewSpace;
}
