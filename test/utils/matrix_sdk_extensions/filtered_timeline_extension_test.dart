import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/matrix_events/event_type_rules.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

void main() {
  // ---------------------------------------------------------------------------
  // EventTypeRules — declarative rule system
  // ---------------------------------------------------------------------------
  group('EventTypeRules', () {
    group('getGroup', () {
      test('core message types are alwaysVisible', () {
        expect(
          EventTypeRules.getGroup(EventTypes.Message),
          EventVisibilityGroup.alwaysVisible,
        );
        expect(
          EventTypeRules.getGroup(EventTypes.Encrypted),
          EventVisibilityGroup.alwaysVisible,
        );
        expect(
          EventTypeRules.getGroup(EventTypes.Sticker),
          EventVisibilityGroup.alwaysVisible,
        );
      });

      test('important state events are alwaysVisible', () {
        for (final type in [
          EventTypes.RoomMember,
          EventTypes.RoomName,
          EventTypes.RoomAvatar,
          EventTypes.RoomCreate,
          EventTypes.RoomTombstone,
        ]) {
          expect(
            EventTypeRules.getGroup(type),
            EventVisibilityGroup.alwaysVisible,
            reason: type,
          );
        }
      });

      test('encryption and metadata state events are unimportant', () {
        for (final type in [
          EventTypes.Encryption,
          EventTypes.GuestAccess,
          EventTypes.HistoryVisibility,
          EventTypes.RoomJoinRules,
          EventTypes.RoomPowerLevels,
          EventTypes.RoomTopic,
        ]) {
          expect(
            EventTypeRules.getGroup(type),
            EventVisibilityGroup.unimportant,
            reason: type,
          );
        }
      });

      test(
        'reaction, redaction, pinned, canonical alias are neverInTimeline',
        () {
          for (final type in [
            EventTypes.Reaction,
            EventTypes.Redaction,
            EventTypes.RoomPinnedEvents,
            EventTypes.RoomCanonicalAlias,
            'm.room.server_acl',
          ]) {
            expect(
              EventTypeRules.getGroup(type),
              EventVisibilityGroup.neverInTimeline,
              reason: type,
            );
          }
        },
      );

      test('calls, policy rules are unknown', () {
        for (final type in [
          EventTypes.CallInvite,
          EventTypes.CallAnswer,
          EventTypes.CallHangup,
          EventTypes.CallCandidates,
          'm.policy.rule.room',
          'm.policy.rule.server',
          'm.policy.rule.user',
          'm.room.message.feedback',
          'm.room.third_party_invite',
        ]) {
          expect(
            EventTypeRules.getGroup(type),
            EventVisibilityGroup.unknown,
            reason: type,
          );
        }
      });

      test('unregistered type falls back to unknown', () {
        expect(
          EventTypeRules.getGroup('com.example.custom'),
          EventVisibilityGroup.unknown,
        );
      });
    });

    group('derived sets', () {
      test('messageContentTypes = message + sticker + encrypted', () {
        expect(
          EventTypeRules.messageContentTypes,
          equals({
            EventTypes.Message,
            EventTypes.Sticker,
            EventTypes.Encrypted,
          }),
        );
      });

      test('userContentTypes = message + sticker + encrypted', () {
        expect(
          EventTypeRules.userContentTypes,
          equals({
            EventTypes.Message,
            EventTypes.Sticker,
            EventTypes.Encrypted,
          }),
        );
      });

      test('showInChatListTypes = message + encrypted', () {
        expect(
          EventTypeRules.showInChatListTypes,
          equals({EventTypes.Message, EventTypes.Encrypted}),
        );
      });
    });

    group('isStateEventType', () {
      test('message content types are NOT state', () {
        for (final type in EventTypeRules.messageContentTypes) {
          expect(EventTypeRules.isStateEventType(type), isFalse, reason: type);
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
          expect(EventTypeRules.isStateEventType(type), isTrue, reason: type);
        }
      });
    });
  });

  // ---------------------------------------------------------------------------
  // isVisibleInGui
  // ---------------------------------------------------------------------------
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

  group('isVisibleInGui — default config', () {
    group('visible events', () {
      test('m.room.message', () {
        expect(makeEvent().isVisibleInGui, isTrue);
      });

      test('m.room.encrypted', () {
        expect(makeEvent(type: EventTypes.Encrypted).isVisibleInGui, isTrue);
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

    group('hidden by neverInTimeline group', () {
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
    });

    group('hidden by unknown group (hideUnknownEvents = true)', () {
      test('m.call.invite', () {
        expect(makeEvent(type: EventTypes.CallInvite).isVisibleInGui, isFalse);
      });

      test('com.example.custom (unregistered)', () {
        expect(
          makeEvent(type: 'com.example.custom', content: {}).isVisibleInGui,
          isFalse,
        );
      });
    });

    group(
      'hidden by unimportant group (hideUnimportantStateEvents = true)',
      () {
        test('m.room.encryption', () {
          expect(
            makeEvent(
              type: EventTypes.Encryption,
              content: {'algorithm': 'm.megolm.v1.aes-sha2'},
            ).isVisibleInGui,
            isFalse,
          );
        });
      },
    );

    group('hidden by relationship', () {
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

      test('key verification events (prefix)', () {
        expect(
          makeEvent(type: 'm.key.verification.request').isVisibleInGui,
          isFalse,
        );
        expect(
          makeEvent(type: 'm.key.verification.start').isVisibleInGui,
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

      test('room name placeholder without display name is hidden', () {
        final e = makeEvent(type: EventTypes.RoomName, content: {});
        expect(e.isVisibleInGui, isFalse);
      });

      test('room name first set with name stays visible', () {
        final e = makeEvent(
          type: EventTypes.RoomName,
          content: {'name': 'My Room'},
        );
        expect(e.isVisibleInGui, isTrue);
      });

      test('room avatar placeholder without url is hidden', () {
        final e = makeEvent(type: EventTypes.RoomAvatar, content: {});
        expect(e.isVisibleInGui, isFalse);
      });

      test('room avatar first set with url stays visible', () {
        final e = makeEvent(
          type: EventTypes.RoomAvatar,
          content: {'url': 'mxc://example/new'},
        );
        expect(e.isVisibleInGui, isTrue);
      });

      test('room avatar change after previous url stays visible', () {
        final e = makeEvent(
          type: EventTypes.RoomAvatar,
          content: {'url': 'mxc://example/new'},
          prevContent: {'url': 'mxc://example/old'},
        );
        expect(e.isVisibleInGui, isTrue);
      });
    });
  });

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

    test(
      'm.room.encryption visible when hideUnimportantStateEvents = false',
      () {
        AppConfig.hideUnimportantStateEvents = false;
        expect(
          makeEvent(
            type: EventTypes.Encryption,
            content: {'algorithm': 'm.megolm.v1.aes-sha2'},
          ).isVisibleInGui,
          isTrue,
        );
      },
    );

    test('m.sticker visible when hideUnknownEvents = true', () {
      AppConfig.hideUnknownEvents = true;
      expect(
        makeEvent(
          type: EventTypes.Sticker,
          content: {'body': ':)', 'url': 'mxc://sticker'},
        ).isVisibleInGui,
        isTrue,
      );
    });

    test('m.call.invite visible when hideUnknownEvents = false', () {
      AppConfig.hideUnknownEvents = false;
      expect(makeEvent(type: EventTypes.CallInvite).isVisibleInGui, isTrue);
    });

    test('unknown type visible when hideUnknownEvents = false', () {
      AppConfig.hideUnknownEvents = false;
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
