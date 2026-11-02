import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_new_group_chat_request.freezed.dart';

@freezed
abstract class CreateNewGroupChatRequest with _$CreateNewGroupChatRequest {
  const factory CreateNewGroupChatRequest({
    String? groupName,
    @Default(<String>[]) List<String> invite,
    bool? enableEncryption,
    String? urlAvatar,

    /// Public preset, listed in the room directory and never encrypted.
    @Default(false) bool isPublic,

    /// Sets `m.federate: false` on a public room; cannot be changed later.
    @Default(false) bool isServerLimited,

    /// The space that holds the group; its members may join it.
    String? parentSpaceId,

    /// A channel the space offers to everyone first.
    @Default(false) bool isSuggested,
  }) = _CreateNewGroupChatRequest;
}
