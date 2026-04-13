import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/matrix_events/event_type_sets.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

void main() {
  late Client client;
  late Room room;

  setUpAll(() async {
    client = await getClient();
    room = Room(
      client: client,
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  late bool savedHideRedacted;
  late bool savedHideUnknown;
  late bool savedHideUnimportant;

  setUp(() {
    savedHideRedacted = AppConfig.hideRedactedEvents;
    savedHideUnknown = AppConfig.hideUnknownEvents;
    savedHideUnimportant = AppConfig.hideUnimportantStateEvents;
    // Match AppConfig static defaults so default-config tests are order-independent.
    AppConfig.hideRedactedEvents = false;
    AppConfig.hideUnknownEvents = true;
    AppConfig.hideUnimportantStateEvents = true;
  });

  tearDown(() {
    AppConfig.hideRedactedEvents = savedHideRedacted;
    AppConfig.hideUnknownEvents = savedHideUnknown;
    AppConfig.hideUnimportantStateEvents = savedHideUnimportant;
  });

  int seq = 0;

  Event makeEvent({
    String type = EventTypes.Message,
    String? senderId,
    Map<String, dynamic> content = const {'body': 'test', 'msgtype': 'm.text'},
    Map<String, dynamic>? prevContent,
    String? stateKey,
    Map<String, dynamic>? unsigned,
    Room? overrideRoom,
  }) {
    seq++;
    return Event(
      senderId: senderId ?? '@other:example.com',
      type: type,
      room: overrideRoom ?? room,
      eventId: '\$ev$seq',
      content: content,
      originServerTs: DateTime.now(),
      prevContent: prevContent,
      stateKey: stateKey,
      unsigned: unsigned,
    );
  }

  // ---------------------------------------------------------------------------
  // isState
  // ---------------------------------------------------------------------------
  group('isState', () {
    test('message content types are NOT state', () {
      for (final type in EventTypeSets.messageContentTypes) {
        expect(makeEvent(type: type).isState, isFalse, reason: type);
      }
    });

    test('other types ARE state', () {
      const stateTypes = [
        EventTypes.RoomMember,
        EventTypes.RoomName,
        EventTypes.RoomAvatar,
        EventTypes.CallInvite,
        EventTypes.Encryption,
        EventTypes.RoomCreate,
      ];
      for (final type in stateTypes) {
        expect(makeEvent(type: type).isState, isTrue, reason: type);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // isVisibleInGui — default AppConfig
  // ---------------------------------------------------------------------------
  group('isVisibleInGui — default config', () {
    group('message-like events are visible', () {
      test('m.room.message', () {
        expect(makeEvent().isVisibleInGui, isTrue);
      });

      test('m.sticker', () {
        expect(
          makeEvent(
            type: EventTypes.Sticker,
            content: {'body': ':)', 'url': 'mxc://sticker'},
          ).isVisibleInGui,
          isTrue,
        );
      });

      test('m.room.encrypted', () {
        expect(makeEvent(type: EventTypes.Encrypted).isVisibleInGui, isTrue);
      });

      test('m.call.invite', () {
        expect(makeEvent(type: EventTypes.CallInvite).isVisibleInGui, isTrue);
      });

      test('m.room.create', () {
        expect(
          makeEvent(
            type: EventTypes.RoomCreate,
            content: {'creator': '@admin:fakeServer'},
          ).isVisibleInGui,
          isTrue,
        );
      });
    });

    group('always-hidden events', () {
      test('edit relationship', () {
        final e = makeEvent(
          content: {
            'body': 'edit',
            'msgtype': 'm.text',
            'm.relates_to': {
              'rel_type': RelationshipTypes.edit,
              'event_id': '\$original',
            },
          },
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('reaction relationship (m.annotation)', () {
        final e = makeEvent(
          type: EventTypes.Reaction,
          content: {
            'm.relates_to': {
              'rel_type': RelationshipTypes.reaction,
              'event_id': '\$original',
              'key': '👍',
            },
          },
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('key verification events', () {
        expect(
          makeEvent(type: 'm.key.verification.request').isVisibleInGui,
          isFalse,
        );
        expect(
          makeEvent(type: 'm.key.verification.start').isVisibleInGui,
          isFalse,
        );
      });

      test('m.reaction type', () {
        expect(
          makeEvent(type: EventTypes.Reaction, content: {}).isVisibleInGui,
          isFalse,
        );
      });

      test('m.room.redaction type', () {
        expect(
          makeEvent(type: EventTypes.Redaction, content: {}).isVisibleInGui,
          isFalse,
        );
      });

      test('m.room.encryption (activation)', () {
        expect(
          makeEvent(
            type: EventTypes.Encryption,
            content: {'algorithm': 'm.megolm.v1.aes-sha2'},
          ).isVisibleInGui,
          isFalse,
        );
      });
    });

    group('content-based filtering', () {
      test('display name change is hidden', () {
        final e = makeEvent(
          type: EventTypes.RoomMember,
          stateKey: '@other:example.com',
          content: {'displayname': 'New Name', 'membership': 'join'},
          prevContent: {'displayname': 'Old Name', 'membership': 'join'},
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('avatar change is hidden', () {
        final e = makeEvent(
          type: EventTypes.RoomMember,
          stateKey: '@other:example.com',
          content: {'avatar_url': 'mxc://new', 'membership': 'join'},
          prevContent: {'avatar_url': 'mxc://old', 'membership': 'join'},
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('self-join is hidden', () {
        final e = makeEvent(
          type: EventTypes.RoomMember,
          senderId: client.userID!,
          stateKey: client.userID!,
          content: {'membership': 'join'},
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('invite without reason is hidden', () {
        final e = makeEvent(
          type: EventTypes.RoomMember,
          stateKey: '@invited:example.com',
          content: {'membership': 'invite'},
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('room name set at creation is hidden', () {
        final e = makeEvent(
          type: EventTypes.RoomName,
          content: {'name': 'My Room'},
        );
        expect(e.isVisibleInGui, isFalse);
      });

      test('room avatar placeholder at creation is hidden', () {
        final e = makeEvent(type: EventTypes.RoomAvatar, content: {});
        expect(e.isVisibleInGui, isFalse);
      });
    });

    test(
      'unknown event type is hidden (hideUnknownEvents defaults to true)',
      () {
        expect(AppConfig.hideUnknownEvents, isTrue);
        expect(
          makeEvent(type: 'com.example.custom', content: {}).isVisibleInGui,
          isFalse,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // isVisibleInGui — config variations
  // ---------------------------------------------------------------------------
  group('isVisibleInGui — config variations', () {
    Map<String, dynamic> redactedUnsigned() => {
      'redacted_because': {
        'event_id': '\$redact',
        'sender': '@mod:example.com',
        'type': EventTypes.Redaction,
        'content': {},
        'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
      },
    };

    test('redacted message hidden when hideRedactedEvents = true', () {
      AppConfig.hideRedactedEvents = true;
      final e = makeEvent(unsigned: redactedUnsigned());
      expect(e.isVisibleInGui, isFalse);
    });

    test('redacted message visible when hideRedactedEvents = false', () {
      AppConfig.hideRedactedEvents = false;
      final e = makeEvent(unsigned: redactedUnsigned());
      expect(e.isVisibleInGui, isTrue);
    });

    test('unknown type visible when hideUnknownEvents = false', () {
      AppConfig.hideUnknownEvents = false;
      AppConfig.hideUnimportantStateEvents = false;
      expect(
        makeEvent(type: 'com.example.custom', content: {}).isVisibleInGui,
        isTrue,
      );
    });

    test('simple join hidden in public room', () {
      final publicRoom = Room(
        client: client,
        id: '!public:example.com',
        membership: Membership.join,
      );
      publicRoom.setState(
        Event(
          type: EventTypes.RoomJoinRules,
          content: {'join_rule': 'public'},
          senderId: '@admin:fakeServer',
          eventId: '\$joinrule',
          room: publicRoom,
          stateKey: '',
          originServerTs: DateTime.now(),
        ),
      );

      final e = makeEvent(
        type: EventTypes.RoomMember,
        senderId: '@someone:example.com',
        stateKey: '@someone:example.com',
        content: {'membership': 'join'},
        overrideRoom: publicRoom,
      );
      expect(e.isVisibleInGui, isFalse);
    });

    test('ban event visible in public room', () {
      final publicRoom = Room(
        client: client,
        id: '!public2:example.com',
        membership: Membership.join,
      );
      publicRoom.setState(
        Event(
          type: EventTypes.RoomJoinRules,
          content: {'join_rule': 'public'},
          senderId: '@admin:fakeServer',
          eventId: '\$joinrule2',
          room: publicRoom,
          stateKey: '',
          originServerTs: DateTime.now(),
        ),
      );

      final e = makeEvent(
        type: EventTypes.RoomMember,
        senderId: '@admin:fakeServer',
        stateKey: '@banned:example.com',
        content: {'membership': 'ban'},
        overrideRoom: publicRoom,
      );
      expect(e.isVisibleInGui, isTrue);
    });
  });
}
