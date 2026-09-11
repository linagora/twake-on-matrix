import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import 'api_login_helper.dart';
import 'base_test_scenario.dart';

const mobileGroupFixtureTitle = 'FTL Mobile Test Group';

/// Title for the chat-list fixtures. It must contain an uppercase "U" so the
/// diacritic-insensitive search probe (`U` -> `Ù`) stays meaningful.
const mobileChatListFixtureTitle = 'FTL Unread Search Group';
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

final Map<String, Future<MobileGroupFixture>> _fixtures = {};

/// Creates (or repairs) the shared mobile-only group fixture and makes sure the
/// configured receiver is a joined member. The fixture is cached for the
/// instrumentation process so the seven group tests do not create seven rooms.
Future<MobileGroupFixture> prepareMobileGroupFixture(
  BaseTestScenario scenario,
) => prepareMobileRoomFixture(scenario, mobileGroupFixtureTitle);

/// Creates (or repairs) a named mobile-only room fixture and makes sure the
/// configured receiver is a joined member. Cached per title for the
/// instrumentation process, so tests that need extra destination rooms (e.g.
/// the forward scenarios) create each one at most once.
Future<MobileGroupFixture> prepareMobileRoomFixture(
  BaseTestScenario scenario,
  String title,
) {
  if (kIsWeb) {
    throw UnsupportedError('The web suite provisions its own Matrix fixture.');
  }
  return _fixtures.putIfAbsent(
    title,
    () => _prepareMobileRoomFixture(scenario, title),
  );
}

Future<MobileGroupFixture> _prepareMobileRoomFixture(
  BaseTestScenario scenario,
  String title,
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
    if (candidate.name == title) {
      room = candidate;
      break;
    }
  }

  if (room == null) {
    final roomId = await client.createRoom(
      name: title,
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
    await scenario.$.pump(const Duration(seconds: 2));
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
    title: title,
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
