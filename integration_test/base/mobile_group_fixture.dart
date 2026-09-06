import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import 'api_login_helper.dart';
import 'base_test_scenario.dart';

const mobileGroupFixtureTitle = 'FTL Mobile Test Group';
const mobileReceiverMessageDisplayMenu = 'FTL receiver fixture display menu';
const mobileReceiverMessageReply = 'FTL receiver fixture reply';
const mobileReceiverMessageDelete = 'FTL receiver fixture delete';
const mobileReceiverMessageCopy = 'FTL receiver fixture copy';

const _receiverFixtureMessages = [
  mobileReceiverMessageDisplayMenu,
  mobileReceiverMessageReply,
  mobileReceiverMessageDelete,
  mobileReceiverMessageCopy,
];

class MobileGroupFixture {
  const MobileGroupFixture({
    required this.roomId,
    required this.title,
    required this.memberMatrixId,
  });

  final String roomId;
  final String title;
  final String memberMatrixId;
}

Future<MobileGroupFixture>? _fixture;

/// Creates (or repairs) the mobile-only group fixture and makes sure the
/// configured receiver is a joined member. The fixture is cached for the
/// instrumentation process so the seven group tests do not create seven rooms.
Future<MobileGroupFixture> prepareMobileGroupFixture(
  BaseTestScenario scenario,
) {
  if (kIsWeb) {
    throw UnsupportedError('The web suite provisions its own Matrix fixture.');
  }
  return _fixture ??= _prepareMobileGroupFixture(scenario);
}

Future<MobileGroupFixture> _prepareMobileGroupFixture(
  BaseTestScenario scenario,
) async {
  const receiver = String.fromEnvironment('Receiver');
  if (receiver.isEmpty) {
    throw StateError('Missing required --dart-define=Receiver');
  }

  await scenario
      .$(ChatList)
      .waitUntilVisible(timeout: const Duration(seconds: 60));
  final context = scenario.$.tester.element(find.byType(Scaffold).first);
  final client = twake.Matrix.of(context).client;
  await client.roomsLoading;
  final receiverMatrixId = _qualifiedMatrixId(receiver, client.userID);

  Room? room;
  for (final candidate in client.rooms) {
    if (candidate.name == mobileGroupFixtureTitle) {
      room = candidate;
      break;
    }
  }

  if (room == null) {
    final roomId = await client.createRoom(
      name: mobileGroupFixtureTitle,
      invite: [receiverMatrixId],
      isDirect: false,
      // Keep the creator at owner level and the invited receiver at the
      // regular member level; the menu assertions exercise that distinction.
      preset: CreateRoomPreset.privateChat,
    );
    room = await _waitForRoom(client, roomId, scenario);
  }

  final receiverMember = await room.requestUser(
    receiverMatrixId,
    requestProfile: false,
  );
  if (receiverMember == null || receiverMember.membership == Membership.leave) {
    try {
      await room.invite(receiverMatrixId);
    } on MatrixException catch (exception) {
      if (!exception.toString().contains('already in the room')) rethrow;
    }
    await ensureReceiverJoined(roomId: room.id);
  } else if (receiverMember.membership != Membership.join) {
    await ensureReceiverJoined(roomId: room.id);
  }

  final joined = await room.requestParticipants([Membership.join]);
  if (!joined.any((participant) => participant.id == receiverMatrixId)) {
    throw StateError(
      'Receiver $receiverMatrixId did not join room ${room.id}.',
    );
  }

  return MobileGroupFixture(
    roomId: room.id,
    title: mobileGroupFixtureTitle,
    memberMatrixId: receiverMatrixId,
  );
}

/// Ensures all receiver-owned messages needed by the group scenarios exist,
/// using at most one receiver login. Each scenario then selects its own stable
/// message, so later Patrol processes do not need to authenticate again.
Future<void> prepareMobileReceiverMessages(
  BaseTestScenario scenario,
  MobileGroupFixture fixture,
) async {
  if (kIsWeb) return;

  final context = scenario.$.tester.element(find.byType(Scaffold).first);
  final client = twake.Matrix.of(context).client;
  final room = client.getRoomById(fixture.roomId);
  if (room == null) {
    throw StateError('Fixture room ${fixture.roomId} is not loaded.');
  }

  final timeline = await room.getTimeline(limit: 100);
  try {
    final existing = timeline.events
        .where((event) => event.senderId == fixture.memberMatrixId)
        .map((event) => event.content['body'])
        .whereType<String>()
        .toSet();
    final missing = _receiverFixtureMessages
        .where((message) => !existing.contains(message))
        .toList();
    if (missing.isNotEmpty) {
      await sendMessagesAsReceiver(messages: missing, roomId: fixture.roomId);
    }
  } finally {
    timeline.cancelSubscriptions();
  }
}

String _qualifiedMatrixId(String receiver, String? currentUserId) {
  if (receiver.startsWith('@') && receiver.contains(':')) return receiver;

  final separator = currentUserId?.indexOf(':') ?? -1;
  if (separator < 0 || separator == currentUserId!.length - 1) {
    throw StateError(
      'Cannot qualify Receiver "$receiver" without a valid current Matrix ID.',
    );
  }
  return '@${receiver.replaceFirst(RegExp(r'^@'), '')}:'
      '${currentUserId.substring(separator + 1)}';
}

Future<Room> _waitForRoom(
  Client client,
  String roomId,
  BaseTestScenario scenario,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    final room = client.getRoomById(roomId);
    if (room != null) return room;
    await scenario.$.pump(const Duration(milliseconds: 500));
  }
  throw StateError('Created fixture room $roomId did not reach the client.');
}
