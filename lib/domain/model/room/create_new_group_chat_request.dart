import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/matrix.dart';

part 'create_new_group_chat_request.freezed.dart';

@freezed
abstract class CreateNewGroupChatRequest with _$CreateNewGroupChatRequest {
  const factory CreateNewGroupChatRequest({
    String? groupName,
    List<String>? invite,
    bool? enableEncryption,
    @Default(CreateRoomPreset.privateChat) CreateRoomPreset createRoomPreset,
    String? urlAvatar,
    Map<String, dynamic>? powerLevelContentOverride,

    /// Public preset, listed in the room directory and never encrypted.
    @Default(false) bool isPublic,

    /// Sets `m.federate: false` on a public room; cannot be changed later.
    @Default(false) bool isServerLimited,
  }) = _CreateNewGroupChatRequest;
}
