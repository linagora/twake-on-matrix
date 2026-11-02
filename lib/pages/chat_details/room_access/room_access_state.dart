import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

part 'room_access_state.freezed.dart';

@freezed
abstract class RoomAccessState with _$RoomAccessState {
  const RoomAccessState._();

  const factory RoomAccessState({
    required RoomAccess saved,
    required JoinRuleChoice? joinRule,
    required bool isListed,
  }) = _RoomAccessState;

  factory RoomAccessState.fromSaved(RoomAccess saved) => RoomAccessState(
    saved: saved,
    joinRule: saved.joinRule,
    isListed: saved.isListed,
  );

  JoinRuleChoice? get changedJoinRule =>
      joinRule != saved.joinRule ? joinRule : null;

  bool? get changedIsListed => isListed != saved.isListed ? isListed : null;

  bool get isDirty => changedJoinRule != null || changedIsListed != null;

  /// An encrypted room keeps what it already has, so it can be taken out.
  List<JoinRuleChoice> get offeredJoinRules => JoinRuleChoice.values
      .where(
        (rule) =>
            rule != JoinRuleChoice.public ||
            !saved.isEncrypted ||
            saved.joinRule == JoinRuleChoice.public,
      )
      .toList();

  bool get showsListing => !saved.isEncrypted || saved.isListed;

  bool get isOrWillBePublic =>
      joinRule == JoinRuleChoice.public ||
      saved.joinRule == JoinRuleChoice.public;
}
