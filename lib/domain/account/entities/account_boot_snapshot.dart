import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_boot_snapshot.freezed.dart';

/// What is read from the store before the first frame, because the account
/// state is built synchronously from it.
@freezed
abstract class AccountBootSnapshot with _$AccountBootSnapshot {
  const factory AccountBootSnapshot({
    /// The Matrix user id persisted as the active account; null when none, and
    /// the first logged-in account is active.
    String? persistedActiveUserId,

    /// The accounts whose removal did not finish before the last exit.
    @Default(<String>{}) Set<String> pendingRemovalIds,
  }) = _AccountBootSnapshot;
}
