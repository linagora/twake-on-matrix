import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';

part 'new_group_form.freezed.dart';

@freezed
abstract class NewGroupForm with _$NewGroupForm {
  const factory NewGroupForm({
    required String groupName,
    required Iterable<String?> invitees,
    required GroupPrivacyState privacy,
    required NewGroupKind kind,
    @Default('') String topic,
    String? parentSpaceId,
    String? urlAvatar,
  }) = _NewGroupForm;
}
