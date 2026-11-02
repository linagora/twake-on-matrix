import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

part 'room_access_draft.freezed.dart';

/// What the user chose in Edit and has not saved yet; null keeps the saved value.
@freezed
abstract class RoomAccessDraft with _$RoomAccessDraft {
  const RoomAccessDraft._();

  const factory RoomAccessDraft({JoinRuleChoice? joinRule, bool? isListed}) =
      _RoomAccessDraft;

  /// Choosing « Public » lists the room; it can still be unlisted before saving.
  RoomAccessDraft choose(JoinRuleChoice rule) => copyWith(
    joinRule: rule,
    isListed: rule == JoinRuleChoice.public ? true : isListed,
  );

  // A choice the room no longer offers (encrypted meanwhile) is dropped.
  JoinRuleChoice? joinRuleOn(RoomAccess saved) {
    final chosen = joinRule;
    return chosen != null && saved.offeredJoinRules.contains(chosen)
        ? chosen
        : saved.joinRule;
  }

  bool isListedOn(RoomAccess saved) {
    final chosen = isListed;
    return chosen != null && saved.offersListing && !saved.hasPublicPage
        ? chosen
        : saved.isListed;
  }

  JoinRuleChoice? changedJoinRuleOn(RoomAccess saved) {
    final chosen = joinRuleOn(saved);
    return chosen != saved.joinRule ? chosen : null;
  }

  bool? changedIsListedOn(RoomAccess saved) {
    final chosen = isListedOn(saved);
    return chosen != saved.isListed ? chosen : null;
  }

  bool isDirtyOn(RoomAccess? saved) =>
      saved != null &&
      (changedJoinRuleOn(saved) != null || changedIsListedOn(saved) != null);

  /// A public room is never encrypted, nor one about to become public.
  bool blocksEncryptionOn(RoomAccess? saved) =>
      saved != null &&
      (saved.joinRule == JoinRuleChoice.public ||
          joinRuleOn(saved) == JoinRuleChoice.public);
}
