import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import 'api_login_helper.dart';
import 'base_test_scenario.dart';

const mobileGroupFixtureTitle = 'FTL Mobile Test Group';

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
  final context = scenario.$.tester.element(find.byType(ChatList).first);
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

  final receiverMember = (await room.requestParticipants()).where(
    (participant) => participant.id == receiverMatrixId,
  );
  if (receiverMember.isEmpty) {
    await room.invite(receiverMatrixId);
    await ensureReceiverJoined(roomId: room.id);
  } else if (receiverMember.first.membership != Membership.join) {
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
