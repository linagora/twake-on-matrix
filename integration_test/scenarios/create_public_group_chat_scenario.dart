import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import '../base/base_test_scenario.dart';

/// Cross-platform scenario: create a public group limited to the homeserver.
///
/// Turns the public groups flag on, creates a group with "Make chat public",
/// then asserts on the homeserver that the room is public, unfederated,
/// unencrypted and listed in the room directory.
///
/// The flag is injected because the test homeserver serves no HTTPS
/// well-known.
class CreatePublicGroupChatScenario extends BaseTestScenario {
  CreatePublicGroupChatScenario(super.$, super.robots);

  static const _memberSearchKey = String.fromEnvironment(
    'SearchByMatrixAddress',
  );

  BuildContext get _context => $.tester.element(find.byType(Scaffold).first);

  Client get _client => twake.Matrix.of(_context).client;

  void _enablePublicGroups() {
    final container = ProviderScope.containerOf(_context);
    final summary = container.read(loginHomeserverSummaryProvider);
    final homeserver = _client.homeserver;
    if (homeserver == null) throw StateError('No homeserver to enable on.');
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(
          HomeserverSummary(
            discoveryInformation: DiscoveryInformation(
              mHomeserver: HomeserverInformation(baseUrl: homeserver),
              additionalProperties: {
                ...?summary?.discoveryInformation?.additionalProperties,
                'app.twake.chat': {
                  'public_groups': {
                    'enabled': true,
                    'default_server_limited': true,
                  },
                },
              },
            ),
            versions: summary?.versions ?? GetVersionsResponse(versions: []),
            loginFlows: summary?.loginFlows ?? [],
          ),
        );
  }

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    _enablePublicGroups();

    final groupName = 'Public ${DateTime.now().millisecondsSinceEpoch}';
    await robots.chatListRobot().createGroupChat(
      groupName,
      _memberSearchKey,
      isPublic: true,
    );

    expect(
      await robots.chatGroupDetailRobot().isVisible(),
      isTrue,
      reason: 'New public group chat view is not shown',
    );

    final client = _client;
    final room = client.rooms.firstWhere((room) => room.name == groupName);
    final joinRules = await client.getRoomStateWithKey(
      room.id,
      EventTypes.RoomJoinRules,
      '',
    );
    final create = await client.getRoomStateWithKey(
      room.id,
      EventTypes.RoomCreate,
      '',
    );
    final directory = await client.queryPublicRooms(
      filter: PublicRoomQueryFilter(genericSearchTerm: groupName),
    );

    expect(joinRules['join_rule'], 'public', reason: 'Group is not public');
    expect(
      create['m.federate'],
      isFalse,
      reason: 'Group is not limited to the homeserver',
    );
    expect(room.encrypted, isFalse, reason: 'Public group is encrypted');
    expect(
      directory.chunk.map((entry) => entry.roomId),
      contains(room.id),
      reason: 'Group is not listed in the room directory',
    );
  }
}
