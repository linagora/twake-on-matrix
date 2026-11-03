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
  }) = _CreateNewGroupChatRequest;
}
