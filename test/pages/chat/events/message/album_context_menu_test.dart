import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/pages/chat/events/message/message_context_menu_action.dart';

import '../../../../lenient_database.dart';

late Room _room;

Event _image(
  String id, {
  EventStatus status = EventStatus.synced,
  String? caption,
}) => Event(
  senderId: '@bob:example.com',
  type: 'm.room.message',
  room: _room,
  eventId: id,
  status: status,
  content: {
    'msgtype': 'm.image',
    'body': caption ?? '$id.png',
    'filename': '$id.png',
  },
  originServerTs: DateTime.utc(2026, 11, 12),
);

/// Gives the signed-in user [ownLevel]; redacting someone else needs 50.
void _setOwnPowerLevel(int ownLevel) => _room.setState(
  Event(
    senderId: '@bob:example.com',
    type: EventTypes.RoomPowerLevels,
    room: _room,
    eventId: 'power-levels',
    stateKey: '',
    content: {
      'redact': 50,
      'events_default': 0,
      'users_default': 0,
      'users': {_room.client.userID!: ownLevel},
    },
    originServerTs: DateTime.utc(2026, 11, 12),
  ),
);

List<MessageContextMenuAction> _menuOf(
  List<Event> members, {
  bool canEditCaption = false,
}) => MessageContentWithTimestampBuilder.albumContextMenuOf(
  members,
  canReply: true,
  canReport: true,
  canEditCaption: canEditCaption,
);

void main() {
  setUpAll(() async => _room = await getLenientRoom('!menu:example.com'));

  test('an album without caption acts as one message, with no Copy', () {
    _setOwnPowerLevel(100);

    expect(_menuOf([_image('a'), _image('b')]), [
      MessageContextMenuAction.reply,
      MessageContextMenuAction.forward,
      MessageContextMenuAction.report,
      MessageContextMenuAction.select,
      MessageContextMenuAction.selectAll,
      MessageContextMenuAction.pin,
      MessageContextMenuAction.saveToGallery,
      MessageContextMenuAction.delete,
    ]);
  });

  test('a caption on the last image adds Copy, and Edit when allowed', () {
    _setOwnPowerLevel(100);
    final members = [_image('a'), _image('b', caption: 'Trip')];

    final menu = _menuOf(members, canEditCaption: true);

    expect(menu, contains(MessageContextMenuAction.copy));
    expect(menu, contains(MessageContextMenuAction.edit));
  });

  test('without the right to delete every image, Delete is not offered', () {
    _setOwnPowerLevel(0);

    expect(
      _menuOf([_image('a'), _image('b')]),
      isNot(contains(MessageContextMenuAction.delete)),
    );
  });

  test('while one image is still sending, there is no album menu', () {
    final members = [_image('a'), _image('b', status: EventStatus.sending)];

    expect(
      MessageContentWithTimestampBuilder.sentAlbumMembersOf(members),
      isNull,
    );
    expect(MessageContentWithTimestampBuilder.sentAlbumMembersOf(null), isNull);
  });
}
