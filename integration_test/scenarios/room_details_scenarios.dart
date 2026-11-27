import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import '../base/base_test_scenario.dart';
import '../robots/group_information_robot.dart';

const _timeout = Duration(seconds: 30);

/// Opens Group info of a group made for the test, then retracts its pending
/// invites and leaves it whatever happens, so no account keeps a trace of it.
abstract class _ThrowawayGroupScenario extends BaseTestScenario {
  _ThrowawayGroupScenario(super.$, super.robots);

  static const _memberMatrixId = String.fromEnvironment('MemberMatrixID');

  String get _titlePrefix;

  Future<void> runOnGroupInfo(Room room, GroupInformationRobot groupInfo);

  Client get _client =>
      twake.Matrix.of($.tester.element(find.byType(Scaffold).first)).client;

  /// Users the test may leave invited: their invites are retracted at the end.
  List<String> get invitedUserIds => const [_memberMatrixId];

  @override
  Future<void> runTestLogic() async {
    await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));
    final client = _client;
    final title = '$_titlePrefix ${DateTime.now().millisecondsSinceEpoch}';
    final roomId = await client.createRoom(
      name: title,
      invite: [_memberMatrixId],
      preset: CreateRoomPreset.privateChat,
    );
    try {
      final room = await _waitForRoom(roomId);
      await robots.chatListRobot().openSearchScreen();
      if (!await robots.searchViewRobot().searchAndOpenRoom(title)) {
        throw Exception('Room "$title" was not found.');
      }
      await robots.chatGroupDetailRobot().tapOnChatBarTitle();
      await runOnGroupInfo(room, GroupInformationRobot($));
    } finally {
      try {
        for (final userId in invitedUserIds) {
          await _retractInvite(client, roomId, userId);
        }
      } finally {
        await client.leaveRoom(roomId);
      }
    }
  }

  Future<void> _retractInvite(
    Client client,
    String roomId,
    String userId,
  ) async {
    final Map<String, Object?> member;
    try {
      member = await client.getRoomStateWithKey(
        roomId,
        EventTypes.RoomMember,
        userId,
      );
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_NOT_FOUND) return;
      rethrow;
    }
    if (member['membership'] == 'invite') await client.kick(roomId, userId);
  }

  Future<Room> _waitForRoom(String roomId) async {
    final deadline = DateTime.now().add(_timeout);
    while (DateTime.now().isBefore(deadline)) {
      final room = _client.getRoomById(roomId);
      if (room != null) return room;
      await $.pump(const Duration(milliseconds: 500));
    }
    throw StateError('Room $roomId did not reach the client.');
  }

  Future<void> waitForServer(bool Function() done, String what) async {
    final deadline = DateTime.now().add(_timeout);
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Timed out waiting for $what.');
      }
      await $.pump(const Duration(milliseconds: 500));
    }
  }
}

/// Edit the group name and description, then see both in Group info.
class RoomDetailsEditInfoScenario extends _ThrowawayGroupScenario {
  RoomDetailsEditInfoScenario(super.$, super.robots);

  @override
  String get _titlePrefix => 'Details edit';

  @override
  Future<void> runOnGroupInfo(
    Room room,
    GroupInformationRobot groupInfo,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final name = 'Renamed $stamp';
    final description = 'Topic $stamp';

    await groupInfo.openEdit();
    await groupInfo.saveGroupInfo(name: name, description: description);
    await groupInfo.closeEdit();

    await $.waitUntilVisible(groupInfo.headerTitle(name), timeout: _timeout);
    await $.waitUntilVisible(
      groupInfo.description(description),
      timeout: _timeout,
    );
    await waitForServer(
      () => room.name == name && room.topic == description,
      'the new name and topic',
    );
  }
}

/// Invite a contact from Group info, then remove them from the group.
class RoomMembersInviteAndRemoveScenario extends _ThrowawayGroupScenario {
  RoomMembersInviteAndRemoveScenario(super.$, super.robots);

  static const _inviteeMatrixId = String.fromEnvironment(
    'SearchByMatrixAddress',
  );

  @override
  String get _titlePrefix => 'Members invite';

  @override
  List<String> get invitedUserIds => const [
    _ThrowawayGroupScenario._memberMatrixId,
    _inviteeMatrixId,
  ];

  Object? _inviteeMembership(Room room) => room
      .getState(EventTypes.RoomMember, _inviteeMatrixId)
      ?.content['membership'];

  @override
  Future<void> runOnGroupInfo(
    Room room,
    GroupInformationRobot groupInfo,
  ) async {
    await groupInfo.expectMember(room.client.userID!);
    await groupInfo.expectMember(_ThrowawayGroupScenario._memberMatrixId);

    await groupInfo.inviteMember(_inviteeMatrixId);
    await groupInfo.expectMember(_inviteeMatrixId);
    await waitForServer(
      () => _inviteeMembership(room) == 'invite',
      'the invite',
    );

    await groupInfo.removeMember(_inviteeMatrixId);
    await waitForServer(() => _inviteeMembership(room) == 'ban', 'the removal');
  }
}

/// Mute the group from Group info, then unmute it.
class RoomDetailsMuteScenario extends _ThrowawayGroupScenario {
  RoomDetailsMuteScenario(super.$, super.robots);

  @override
  String get _titlePrefix => 'Details mute';

  @override
  Future<void> runOnGroupInfo(
    Room room,
    GroupInformationRobot groupInfo,
  ) async {
    await groupInfo.toggleMute(muted: false);
    await waitForServer(
      () => room.pushRuleState != PushRuleState.notify,
      'the mute push rule',
    );

    await groupInfo.toggleMute(muted: true);
    await waitForServer(
      () => room.pushRuleState == PushRuleState.notify,
      'the unmute',
    );
  }
}
