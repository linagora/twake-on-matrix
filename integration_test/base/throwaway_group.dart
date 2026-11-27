import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import 'base_test_scenario.dart';

const _timeout = Duration(seconds: 30);

/// Runs [body] in a private group made for the test with [invite] invited,
/// opened on Group info. Whatever happens, the invites still pending are
/// retracted, the bans lifted, then the group is left.
Future<void> runInThrowawayGroup(
  BaseTestScenario scenario, {
  required String titlePrefix,
  required List<String> invite,
  required Future<void> Function(Room room) body,
}) async {
  final $ = scenario.$;
  await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));
  final client = twake.Matrix.of(
    $.tester.element(find.byType(Scaffold).first),
  ).client;
  final title = '$titlePrefix ${DateTime.now().millisecondsSinceEpoch}';
  final roomId = await client.createRoom(
    name: title,
    invite: invite,
    preset: CreateRoomPreset.privateChat,
  );
  try {
    final room = await _waitForRoom(scenario, client, roomId);
    await scenario.robots.chatListRobot().openSearchScreen();
    if (!await scenario.robots.searchViewRobot().searchAndOpenRoom(title)) {
      throw Exception('Room "$title" was not found.');
    }
    await scenario.robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await body(room);
  } finally {
    try {
      for (final userId in invite) {
        await _undoMembership(client, roomId, userId);
      }
    } finally {
      await client.leaveRoom(roomId);
    }
  }
}

/// Polls the local [Room] until [done] holds, the server change having to
/// come back through /sync.
Future<void> waitForSync(
  BaseTestScenario scenario,
  bool Function() done,
  String what,
) async {
  final deadline = DateTime.now().add(_timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for $what.');
    }
    await scenario.$.pump(const Duration(milliseconds: 500));
  }
}

String? membershipOf(Room room, String userId) =>
    room.getState(EventTypes.RoomMember, userId)?.content['membership']
        as String?;

Future<void> _undoMembership(
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
  switch (member['membership']) {
    case 'invite':
      await client.kick(roomId, userId);
    case 'ban':
      await client.unban(roomId, userId);
  }
}

Future<Room> _waitForRoom(
  BaseTestScenario scenario,
  Client client,
  String roomId,
) async {
  final deadline = DateTime.now().add(_timeout);
  while (DateTime.now().isBefore(deadline)) {
    final room = client.getRoomById(roomId);
    if (room != null) return room;
    await scenario.$.pump(const Duration(milliseconds: 500));
  }
  throw StateError('Room $roomId did not reach the client.');
}
