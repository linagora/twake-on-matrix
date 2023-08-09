import 'package:matrix/matrix.dart';

extension RoomSummaryExtension on RoomSummary {
  int get actualMembersCount =>
      (mInvitedMemberCount ?? 0) + (mJoinedMemberCount ?? 0);
}
