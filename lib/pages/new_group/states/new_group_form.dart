import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';

part 'new_group_form.freezed.dart';

@freezed
abstract class NewGroupForm with _$NewGroupForm {
  const factory NewGroupForm({
    required String groupName,
    required Iterable<String?> invitees,
    required bool enableEncryption,
    required GroupPrivacyState privacy,
    required bool isFeed,
    String? urlAvatar,
  }) = _NewGroupForm;
}
