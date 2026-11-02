import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/events/images_builder/message_content_image_builder.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/chat/events/sticker.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';

const _webSourceRoom = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

const _webSourceRoomId = String.fromEnvironment('GroupID');

const _receiver = String.fromEnvironment(
  'ForwardReceiver1Name',
  defaultValue: 'Receiver Alpha',
);

/// Receives a sticker (as from Element), forwards it to [_receiver], and
/// checks it arrives as an image rather than as its text description.
abstract class ForwardStickerScenario extends BaseTestScenario {
  ForwardStickerScenario(super.$, super.robots);

  /// Returns the id and title of the room that receives the sticker.
  Future<({String id, String title})> prepareSourceRoom();

  @override
  Future<void> runTestLogic() async {
    final source = await prepareSourceRoom();
    final stickerBody = 'sticker-${DateTime.now().microsecondsSinceEpoch}';
    await sendStickerAsReceiver(body: stickerBody, roomId: source.id);
    await _waitForLastEvent(
      roomOf: (client) => client.getRoomById(source.id),
      matches: (event) =>
          event.type == EventTypes.Sticker && event.body == stickerBody,
      reason: 'the received sticker',
    );

    await robots.chatListRobot().openSearchScreen();
    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      source.title,
    );
    if (!opened) {
      throw Exception('Test failed: Room "${source.title}" was not found.');
    }
    await $.pump(const Duration(seconds: 1));

    await robots.messageMenuRobot().openForwardOnLast(
      find.byWidgetPredicate(
        (widget) => widget is Sticker && widget.event.body == stickerBody,
      ),
    );

    final forward = robots.forwardRobot();
    await forward.searchRoom(_receiver);
    await forward.verifyRoomInList(_receiver);
    await forward.selectChatByName(_receiver);
    await forward.tapSendButton();
    await forward.verifyOpenedRoom(_receiver);

    await _verifyForwardedAsImage(stickerBody);
  }

  Future<void> _verifyForwardedAsImage(String stickerBody) async {
    await _waitForLastEvent(
      roomOf: (client) =>
          client.rooms.where((room) => room.name == _receiver).firstOrNull,
      matches: (event) =>
          event.type == EventTypes.Message &&
          event.messageType == MessageTypes.Image &&
          event.body == stickerBody,
      reason: 'the forwarded sticker as an image',
    );
    // The mobile receiver room is persistent and keeps older images.
    await $.waitUntilExists(
      $(
        find.byWidgetPredicate(
          (widget) =>
              widget is MessageContent &&
              widget.event.messageType == MessageTypes.Image &&
              widget.event.body == stickerBody,
        ),
      ).containing(find.byType(MessageImageBuilder)),
      timeout: const Duration(seconds: 30),
    );
    expect(
      $(
        MessageContent,
      ).containing(find.textContaining(stickerBody, findRichText: true)),
      findsNothing,
      reason: 'the sticker must not be forwarded as its text description',
    );
  }

  Future<void> _waitForLastEvent({
    required Room? Function(Client client) roomOf,
    required bool Function(Event event) matches,
    required String reason,
  }) async {
    final context = $.tester.element(find.byType(Scaffold).first);
    final client = twake.Matrix.of(context).client;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final lastEvent = roomOf(client)?.lastEvent;
      if (lastEvent != null && matches(lastEvent)) return;
      await $.pump(const Duration(milliseconds: 500));
    }
    final lastEvent = roomOf(client)?.lastEvent;
    fail(
      'Timed out waiting for $reason; last event is '
      '${lastEvent?.type} ${lastEvent?.content}',
    );
  }
}

class ForwardStickerMobileScenario extends ForwardStickerScenario {
  ForwardStickerMobileScenario(super.$, super.robots);

  @override
  Future<({String id, String title})> prepareSourceRoom() async {
    final fixture = await prepareMobileGroupFixture(this);
    await prepareMobileRoomFixture(this, _receiver);
    return (id: fixture.roomId, title: fixture.title);
  }
}

class ForwardStickerWebScenario extends ForwardStickerScenario {
  ForwardStickerWebScenario(super.$, super.robots);

  @override
  Future<({String id, String title})> prepareSourceRoom() async =>
      (id: _webSourceRoomId, title: _webSourceRoom);
}
