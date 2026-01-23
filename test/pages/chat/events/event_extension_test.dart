import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';

import '../../../fake_client.dart';
import 'event_extension_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ContactsManager>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockContactsManager mockContactsManager;

  setUp(() {
    mockContactsManager = MockContactsManager();
    final getIt = GetIt.instance;
    getIt.registerSingleton<ContactsManager>(
      mockContactsManager,
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group(
    'Can edit event with room not encrypted test',
    () {
      late Client client;

      late Room room;

      test('Login', () async {
        client = await getClient();
        const id = '!localpart:server.abc';
        const membership = Membership.join;
        const notificationCount = 2;
        const highlightCount = 1;
        final heroes = [
          '@alice:matrix.org',
          '@bob:example.com',
          '@charley:example.org',
        ];
        room = Room(
          client: client,
          id: id,
          membership: membership,
          highlightCount: highlightCount,
          notificationCount: notificationCount,
          prev_batch: '',
          summary: RoomSummary.fromJson({
            'm.joined_member_count': 2,
            'm.invited_member_count': 2,
            'm.heroes': heroes,
          }),
          roomAccountData: {
            'com.test.foo': BasicEvent(
              type: 'com.test.foo',
              content: {'foo': 'bar'},
            ),
            'm.fully_read': BasicEvent(
              type: 'm.fully_read',
              content: {'event_id': '\$event_id:example.com'},
            ),
          },
        );
      });

      test('PowerLevels', () async {
        room.setState(
          Event(
            senderId: '@test:example.com',
            type: 'm.room.power_levels',
            room: room,
            eventId: '123',
            content: {
              'ban': 50,
              'events': {'m.room.name': 100, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {'@admin:fakeServer': 100},
              'users_default': 10,
            },
            originServerTs: DateTime.now(),
            stateKey: '',
          ),
        );
        expect(room.ownPowerLevel, 100);
        expect(room.getPowerLevelByUserId(client.userID!), room.ownPowerLevel);
        expect(room.getPowerLevelByUserId('@nouser:example.com'), 10);
        expect(room.ownPowerLevel, 100);
        expect(room.canBan, true);
        expect(room.canInvite, true);
        expect(room.canKick, true);
        expect(room.canRedact, true);
        expect(room.canSendDefaultMessages, true);
        expect(room.canChangePowerLevel, true);
        expect(room.canSendEvent('m.room.name'), true);
        expect(room.canSendEvent('m.room.power_levels'), true);
        expect(room.canSendEvent('m.room.member'), true);
        room.setState(
          Event(
            senderId: '@test:example.com',
            type: 'm.room.power_levels',
            room: room,
            eventId: '123',
            content: {
              'ban': 50,
              'events': {
                'm.room.name': 'lannaForcedMeToTestThis',
                'm.room.power_levels': 100,
              },
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 60,
              'users': {'@test:fakeServer.notExisting': 100},
              'users_default': 10,
            },
            originServerTs: DateTime.now(),
            stateKey: '',
          ),
        );
        expect(room.powerForChangingStateEvent('m.room.name'), 60);
        expect(room.powerForChangingStateEvent('m.room.power_levels'), 100);
        expect(room.powerForChangingStateEvent('m.room.nonExisting'), 60);

        room.setState(
          Event(
            senderId: '@test:example.com',
            type: 'm.room.power_levels',
            room: room,
            eventId: '123abc',
            content: {
              'ban': 50,
              'events': {'m.room.name': 0, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {},
              'users_default': 0,
            },
            originServerTs: DateTime.now(),
            stateKey: '',
          ),
        );
        expect(room.ownPowerLevel, 0);
        expect(room.canBan, false);
        expect(room.canInvite, false);
        expect(room.canKick, false);
        expect(room.canRedact, false);
        expect(room.canSendDefaultMessages, true);
        expect(room.canChangePowerLevel, false);
        expect(room.canChangeStateEvent('m.room.name'), true);
        expect(room.canChangeStateEvent('m.room.power_levels'), false);
        expect(room.canChangeStateEvent('m.room.member'), false);
        expect(room.canSendEvent('m.room.message'), true);
      });

      test(
        'Room is encrypted and event is not encrypted then can edit is true',
        () {
          final event = Event(
            content: {
              "body": "Nhiều thế",
              "msgtype": "m.text",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
            room: room,
          );

          expect(event.isBadEncryptedEvent(), isFalse);
        },
      );
    },
  );

  group(
    'Can edit event with room  encrypted test',
    () {
      late Client client;

      late Room room;

      test('Login', () async {
        client = await getClient();
        const id = '!localpart:server.abc';
        const membership = Membership.join;
        const notificationCount = 2;
        const highlightCount = 1;
        final heroes = [
          '@alice:matrix.org',
          '@bob:example.com',
          '@charley:example.org',
        ];
        room = Room(
          client: client,
          id: id,
          membership: membership,
          highlightCount: highlightCount,
          notificationCount: notificationCount,
          prev_batch: '',
          summary: RoomSummary.fromJson({
            'm.joined_member_count': 2,
            'm.invited_member_count': 2,
            'm.heroes': heroes,
          }),
          roomAccountData: {
            'com.test.foo': BasicEvent(
              type: 'com.test.foo',
              content: {'foo': 'bar'},
            ),
            'm.fully_read': BasicEvent(
              type: 'm.fully_read',
              content: {'event_id': '\$event_id:example.com'},
            ),
          },
        );
      });

      test('Enable encryption', () async {
        room.setState(
          Event(
            senderId: '@alice:test.abc',
            type: 'm.room.encryption',
            room: room,
            eventId: '12345',
            originServerTs: DateTime.now(),
            content: {
              'algorithm': AlgorithmTypes.megolmV1AesSha2,
              'rotation_period_ms': 604800000,
              'rotation_period_msgs': 100,
            },
            stateKey: '',
          ),
        );
        expect(room.encrypted, true);
        expect(room.encryptionAlgorithm, AlgorithmTypes.megolmV1AesSha2);
      });

      test('PowerLevels', () async {
        room.setState(
          Event(
            senderId: '@test:example.com',
            type: 'm.room.power_levels',
            room: room,
            eventId: '123abc',
            content: {
              'ban': 50,
              'events': {'m.room.name': 0, 'm.room.power_levels': 100},
              'events_default': 0,
              'invite': 50,
              'kick': 50,
              'notifications': {'room': 20},
              'redact': 50,
              'state_default': 50,
              'users': {},
              'users_default': 0,
            },
            originServerTs: DateTime.now(),
            stateKey: '',
          ),
        );
        expect(room.ownPowerLevel, 0);
        expect(room.canBan, false);
        expect(room.canInvite, false);
        expect(room.canKick, false);
        expect(room.canRedact, false);
        expect(room.canSendDefaultMessages, true);
        expect(room.canChangePowerLevel, false);
        expect(room.canChangeStateEvent('m.room.name'), true);
        expect(room.canChangeStateEvent('m.room.power_levels'), false);
        expect(room.canChangeStateEvent('m.room.member'), false);
        expect(room.canSendEvent('m.room.message'), true);
      });

      test(
        'Room is encrypted and event is not encrypted then can edit is false',
        () {
          final event = Event(
            content: {
              "sender_key": "x2gIpXwvtJ/ZL/5/NpE4rHiC2RF9hJ0Mn4InrJWY3z8",
              "session_id": "aiHfG0xgmXq6Nd7zk+O9TTS82pHgZfoVBsitPnJBoSI",
              "algorithm": "m.megolm.v1.aes-sha2",
              "device_id": "ITHGXKSYSE",
              "ciphertext":
                  "AwgBEoABnHUwJ8Nj/Ts5iZOCg0uaqG+vzL88hc6px8EOk7CDRhsKQK+mqIWABKLEDc3gnobGWEQ3uFXxKCCPXBkWlwJtiGy1KDh5cXVDV2tE7QOa98PslwQEjKDKpoIxJCrHsesNe4FI17qtd5G5qqZYSYHzLLIvZTqg4+R3lvzTMy+zTIuQOKHQ/kVh/eBnfwuwhyJFGClXAqKbHsujtW23pKrM5yrHOa63bO0qnMwwGwZx8ZBM8/sIUymHzUWkbG25Wm4wUhkZTPhQFwc",
              "body": "The sender has not sent us the session key.",
              "msgtype": "m.bad.encrypted",
              "can_request_session": true,
            },
            type: 'm.room.encrypted',
            eventId: '\$143223582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
            room: room,
          );

          expect(event.isBadEncryptedEvent(), isTrue);
        },
      );

      test(
        'Room is encrypted and event is decrypted then can edit is true',
        () {
          final event = Event(
            content: {"body": "test", "msgtype": "m.text"},
            type: 'm.room.encrypted',
            eventId: '\$143223582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
            room: room,
          );

          expect(event.isBadEncryptedEvent(), isFalse);
        },
      );

      test(
        'Room is encrypted and event is decrypted and msgtype is image then can edit is true',
        () {
          final event = Event(
            content: {
              "body": "IMG_1355-1748319344150.jpeg",
              "filename": "IMG_1355-1748319344150.jpeg",
              "info": {
                "h": 1600,
                "mimetype": "image/jpeg",
                "size": 386505,
                "thumbnail_info": {
                  "h": 800,
                  "mimetype": "image/jpeg",
                  "size": 108179,
                  "w": 600,
                  "xyz.amorgan.blurhash": "KGH_f7IS4:yCrWV@0#VYxC",
                },
                "thumbnail_url":
                    "mxc://stg.lin-saas.com/LegeQNfVjkXRRQoUDlxacimD",
                "w": 1200,
                "xyz.amorgan.blurhash": "KGH_f7IS4:yCrWV@0#VYxC",
              },
              "msgtype": "m.image",
              "url": "mxc://stg.lin-saas.com/KkhrPabsJfReWzdCPRWRGUfV",
            },
            type: 'm.room.encrypted',
            eventId: '\$143223582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
            room: room,
          );

          expect(event.isBadEncryptedEvent(), isFalse);
        },
      );

      test(
        'Room is encrypted and event is decrypted and msgtype is video then can edit is true',
        () {
          final event = Event(
            content: {
              "body":
                  "Simulator Screen Recording - iPhone 16 - 2025-05-22 at 11.40.28.mp4",
              "filename":
                  "Simulator Screen Recording - iPhone 16 - 2025-05-22 at 11.40.28.mp4",
              "info": {
                "duration": 13667,
                "h": 2556,
                "mimetype": "video/mp4",
                "size": 7097194,
                "thumbnail_info": {
                  "h": 2556,
                  "mimetype": "image/jpeg",
                  "size": 97476,
                  "w": 1178,
                  "xyz.amorgan.blurhash": "LDR._q?H-s_34ga\$jdWE4hoh%3af",
                },
                "thumbnail_url":
                    "mxc://stg.lin-saas.com/ypjjyxkerLpKmwPVxQjRzenl",
                "w": 1178,
                "xyz.amorgan.blurhash": "LDR._q?H-s_34ga\$jdWE4hoh%3af",
              },
              "msgtype": "m.video",
              "url": "mxc://stg.lin-saas.com/wTnKGoYuOSBBZoolRjtnyozg",
            },
            type: 'm.room.encrypted',
            eventId: '\$143223582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
            room: room,
          );

          expect(event.isBadEncryptedEvent(), isFalse);
        },
      );
    },
  );

  group('LocalizedBody.isSameEvent', () {
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

    Event createEvent({
      required String eventId,
      String? transactionId,
      String body = 'test',
      int timestamp = 1234567890,
    }) {
      return Event(
        senderId: '@user:example.com',
        type: 'm.room.message',
        room: room,
        eventId: eventId,
        content: {'body': body},
        originServerTs: DateTime.fromMillisecondsSinceEpoch(timestamp),
        unsigned:
            transactionId != null ? {'transaction_id': transactionId} : null,
      );
    }

    test('should return true when eventIds match', () {
      final event1 = createEvent(eventId: '\$event1');
      final event2 = createEvent(eventId: '\$event1');

      expect(event1.isSameEvent(event2), true);
    });

    test('should return true when transaction IDs match', () {
      final event1 = createEvent(
        eventId: '\$event1',
        transactionId: 'txn123',
      );
      final event2 = createEvent(
        eventId: '\$event2',
        transactionId: 'txn123',
      );

      expect(event1.isSameEvent(event2), true);
    });

    test(
      'should return true when one event\'s eventId matches other\'s transaction_id',
      () {
        final sendingEvent = createEvent(
          eventId: 'txn123',
          transactionId: 'txn123',
        );
        final sentEvent = createEvent(eventId: 'txn123');

        expect(sendingEvent.isSameEvent(sentEvent), true);
        expect(sentEvent.isSameEvent(sendingEvent), true);
      },
    );

    test('should return false when events are different', () {
      final event1 = createEvent(eventId: '\$event1');
      final event2 = createEvent(eventId: '\$event2');

      expect(event1.isSameEvent(event2), false);
    });
  });

  group('LocalizedBody.findEventInMap', () {
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

    Event createEvent({
      required String eventId,
      String? transactionId,
      String body = 'test',
    }) {
      return Event(
        senderId: '@user:example.com',
        type: 'm.room.message',
        room: room,
        eventId: eventId,
        content: {'body': body},
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1234567890),
        unsigned:
            transactionId != null ? {'transaction_id': transactionId} : null,
      );
    }

    Map<String, Event> buildEventMap(List<Event> events) {
      final map = <String, Event>{};
      for (final event in events) {
        map[event.eventId] = event;
        final transactionId = event.unsigned?['transaction_id'] as String?;
        if (transactionId != null) {
          map[transactionId] = event;
        }
      }
      return map;
    }

    test('should find event by eventId', () {
      final event = createEvent(eventId: '\$event1');
      final map = buildEventMap([event]);
      final found = event.findEventInMap(map);

      expect(found, event);
    });

    test('should find event by transactionId', () {
      final originalEvent = createEvent(
        eventId: '\$event1',
        transactionId: 'txn123',
      );
      final searchEvent = createEvent(
        eventId: '\$different',
        transactionId: 'txn123',
      );

      final map = buildEventMap([originalEvent]);
      final found = searchEvent.findEventInMap(map);

      expect(found, originalEvent);
    });

    test('should return null when event not found', () {
      final event = createEvent(eventId: '\$event1');
      final map = <String, Event>{};
      final found = event.findEventInMap(map);

      expect(found, null);
    });
  });

  group('isMention test', () {
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

    Event createEvent({
      required Map<String, dynamic> content,
      String eventId = '\$event1',
      String senderId = '@user:example.com',
    }) {
      return Event(
        senderId: senderId,
        type: 'm.room.message',
        room: room,
        eventId: eventId,
        content: content,
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1234567890),
      );
    }

    test(
        'returns false when formatted_body contains matrix.to link NOT mentioning current user',
        () {
      final event = createEvent(
        content: {
          'body': 'User hello',
          'format': 'org.matrix.custom.html',
          'formatted_body':
              '<a href="https://matrix.to/#/@otheruser:example.com">User</a> hello',
          'msgtype': 'm.text',
        },
      );

      expect(event.isMention, false);
    });

    test(
        'returns true when formatted_body contains matrix.to link mentioning current user',
        () {
      final event = createEvent(
        content: {
          'body': 'admin hello',
          'format': 'org.matrix.custom.html',
          'formatted_body':
              '<a href="https://matrix.to/#/@admin:fakeServer">User</a> hello',
          'msgtype': 'm.text',
        },
      );

      expect(event.isMention, true);
    });

    test('returns false when formatted_body is not present', () {
      final event = createEvent(
        content: {
          'body': 'Message to @admin:fakeServer',
          'msgtype': 'm.text',
        },
      );

      expect(event.isMention, false);
    });

    test('returns false when body is empty and no formatted_body', () {
      final event = createEvent(
        content: {
          'body': '',
          'msgtype': 'm.text',
        },
      );

      expect(event.isMention, false);
    });

    test(
        'returns false when formatted_body has multiple matrix.to links but NOT current user',
        () {
      final event = createEvent(
        content: {
          'body': 'Alice and Bob',
          'format': 'org.matrix.custom.html',
          'formatted_body':
              '<a href="https://matrix.to/#/@alice:example.com">Alice</a> and <a href="https://matrix.to/#/@bob:example.com">Bob</a>',
          'msgtype': 'm.text',
        },
      );

      expect(event.isMention, false);
    });

    test('returns false when formatted_body is empty string', () {
      final event = createEvent(
        content: {
          'body': 'Hello @admin:fakeServer',
          'format': 'org.matrix.custom.html',
          'formatted_body': '',
          'msgtype': 'm.text',
        },
      );

      // Empty formatted_body should return false
      expect(event.isMention, false);
    });
  });

  group('isCaptionModeOrReply test', () {
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

    Event createEvent({
      required Map<String, dynamic> content,
      String eventId = '\$event1',
      String senderId = '@user:example.com',
    }) {
      return Event(
        senderId: senderId,
        type: 'm.room.message',
        room: room,
        eventId: eventId,
        content: content,
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1234567890),
      );
    }

    test(
      'GIVEN image event with empty body\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': '',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
          },
        );

        expect(event.isCaptionModeOrReply(), false);
      },
    );

    test(
      'GIVEN image event with body same as filename\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': '',
            'filename': 'image.jpg',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
          },
        );

        expect(event.isCaptionModeOrReply(), false);
      },
    );

    test(
      'GIVEN image event with body different from filename\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'My vacation photo',
            'filename': 'image.jpg',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );

    test(
      'GIVEN video event with body different from filename\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'Birthday party',
            'filename': 'video.mp4',
            'msgtype': 'm.video',
            'url': 'mxc://example.org/video123',
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );

    test(
      'GIVEN file event with body different from filename\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'Important document',
            'filename': 'report.pdf',
            'msgtype': 'm.file',
            'url': 'mxc://example.org/file123',
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );

    test(
      'GIVEN text event that is a reply\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'This is a reply',
            'msgtype': 'm.text',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );

    test(
      'GIVEN image event that is a reply\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'image.jpg',
            'filename': 'image.jpg',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );

    test(
      'GIVEN text event with no caption or reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'Just a regular message',
            'msgtype': 'm.text',
          },
        );

        expect(event.isCaptionModeOrReply(), false);
      },
    );

    test(
      'GIVEN image event with no filename field (body differs from null)\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'image.jpg',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
          },
        );

        expect(event.isCaptionModeOrReply(), true);
      },
    );
  });

  group('isReplyEventWithAudio test', () {
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

    Event createEvent({
      required Map<String, dynamic> content,
      String eventId = '\$event1',
      String senderId = '@user:example.com',
    }) {
      return Event(
        senderId: senderId,
        type: 'm.room.message',
        room: room,
        eventId: eventId,
        content: content,
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1234567890),
      );
    }

    test(
      'GIVEN audio event that is a reply\n'
      'THEN return true\n',
      () {
        final event = createEvent(
          content: {
            'body': 'audio.mp3',
            'msgtype': 'm.audio',
            'url': 'mxc://example.org/audio123',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isReplyEventWithAudio(), true);
      },
    );

    test(
      'GIVEN audio event that is NOT a reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'audio.mp3',
            'msgtype': 'm.audio',
            'url': 'mxc://example.org/audio123',
          },
        );

        expect(event.isReplyEventWithAudio(), false);
      },
    );

    test(
      'GIVEN image event that is a reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'image.jpg',
            'msgtype': 'm.image',
            'url': 'mxc://example.org/image123',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isReplyEventWithAudio(), false);
      },
    );

    test(
      'GIVEN text event that is a reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'This is a reply',
            'msgtype': 'm.text',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isReplyEventWithAudio(), false);
      },
    );

    test(
      'GIVEN video event that is a reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'video.mp4',
            'msgtype': 'm.video',
            'url': 'mxc://example.org/video123',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isReplyEventWithAudio(), false);
      },
    );

    test(
      'GIVEN file event that is a reply\n'
      'THEN return false\n',
      () {
        final event = createEvent(
          content: {
            'body': 'document.pdf',
            'msgtype': 'm.file',
            'url': 'mxc://example.org/file123',
            'm.relates_to': {
              'm.in_reply_to': {
                'event_id': '\$original_event',
              },
            },
          },
        );

        expect(event.isReplyEventWithAudio(), false);
      },
    );
  });
}
