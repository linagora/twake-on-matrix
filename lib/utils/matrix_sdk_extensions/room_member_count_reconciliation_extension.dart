import 'package:fluffychat/utils/logging/sentry_tracked_events.dart';
import 'package:matrix/matrix.dart';

/// TODO(TW-2968): client-side workaround for a Synapse bug that omits
/// member-count deltas — https://github.com/element-hq/synapse/issues/19865
/// Remove this reconciliation once Synapse is fixed (keep the
/// `Wrong-member-count` Sentry tag to confirm the fix landed).
extension RoomMemberCountReconciliationExtension on Room {
  /// Only reconciles when [membershipFilter] contains both [Membership.join]
  /// and [Membership.invite]: otherwise the list is not usable.
  Future<List<User>> requestParticipantsWithSummaryReconciliation([
    List<Membership> membershipFilter = const [
      Membership.join,
      Membership.invite,
      Membership.knock,
    ],
    bool suppressWarning = false,
    bool? cache,
  ]) async {
    final participants = await requestParticipants(
      membershipFilter,
      suppressWarning,
      cache,
    );
    if (membershipFilter.contains(Membership.join) &&
        membershipFilter.contains(Membership.invite)) {
      await healSummaryMemberCounts(participants);
    }
    return participants;
  }

  /// Updates the summary member counts, in memory and in database, when they
  /// diverge
  Future<void> healSummaryMemberCounts(
    List<User> groundTruthParticipants,
  ) async {
    // A synthetic JoinedRoomUpdate on a non-joined or unknown room would
    // corrupt its membership or restore it in the room list.
    if (membership != Membership.join || client.getRoomById(id) == null) {
      return;
    }
    final joinedCount = groundTruthParticipants
        .where((user) => user.membership == Membership.join)
        .length;
    final invitedCount = groundTruthParticipants
        .where((user) => user.membership == Membership.invite)
        .length;
    // A joined room always has at least one joined member (the syncing user)
    if (joinedCount == 0) {
      return;
    }
    if (summary.mJoinedMemberCount == joinedCount &&
        summary.mInvitedMemberCount == invitedCount) {
      return;
    }
    Logs().w(
      '${SentryTrackedEvents.wrongMemberCount.message}: healing summary of '
      '$id from (joined=${summary.mJoinedMemberCount}, '
      'invited=${summary.mInvitedMemberCount}) to (joined=$joinedCount, '
      'invited=$invitedCount)',
    );
    // Feed the corrected counts through the regular sync pipeline, as if the
    // server had sent them: same merge (heroes preserved), same persistence
    // and UI notifications as a real summary update.
    await client.database.transaction(() async {
      await client.handleSync(
        SyncUpdate(
          nextBatch: '',
          rooms: RoomsUpdate(
            join: {
              id: JoinedRoomUpdate(
                summary: RoomSummary.fromJson({
                  'm.joined_member_count': joinedCount,
                  'm.invited_member_count': invitedCount,
                }),
              ),
            },
          ),
        ),
      );
    });
  }
}
