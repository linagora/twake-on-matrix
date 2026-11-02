import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_access.freezed.dart';

enum JoinRuleChoice { invite, knock, public }

@freezed
abstract class RoomAccess with _$RoomAccess {
  const RoomAccess._();

  const factory RoomAccess({
    /// Null for a rule that is none of the choices, such as `restricted`.
    required JoinRuleChoice? joinRule,
    required bool isListed,
    required bool isEncrypted,
    required bool canChange,
  }) = _RoomAccess;

  /// An encrypted room keeps what it already has, so it can be taken out.
  List<JoinRuleChoice> get offeredJoinRules => JoinRuleChoice.values
      .where(
        (rule) =>
            rule != JoinRuleChoice.public ||
            !isEncrypted ||
            joinRule == JoinRuleChoice.public,
      )
      .toList();

  bool get offersListing => !isEncrypted || isListed;
}
