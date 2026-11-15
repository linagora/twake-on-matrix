import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/direct_chat/datasources_impl/direct_chat_datasource_impl.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';

class _FakeSummary extends Fake implements RoomSummary {
  @override
  int? get mJoinedMemberCount => 2;
}

class _FakeRoom extends Fake implements Room {
  _FakeRoom({
    required this.id,
    this.membership = Membership.join,
    this.peer = '@alice:server',
    this.abandoned = false,
    this.joinedAfterJoin = true,
  });

  @override
  final String id;
  @override
  Membership membership;
  final String? peer;
  final bool abandoned;
  final bool joinedAfterJoin;
  bool joinCalled = false;

  @override
  bool get isAbandonedDMRoom => abandoned;
  @override
  bool get isDirectChat => true;
  @override
  String? get directChatMatrixID => peer;
  @override
  RoomSummary get summary => _FakeSummary();
  @override
  List<User> getParticipants([List<Membership>? membershipFilter]) => [];

  @override
  Future<void> join({bool leaveIfNotFound = true}) async {
    joinCalled = true;
    if (joinedAfterJoin) membership = Membership.join;
  }
}

class _FakeClient extends Fake implements Client {
  Object? profileError;
  Object? syncError;
  Object? createError;
  bool registerCreatedRoom = false;
  String? directRoomId;
  final knownRooms = <String, Room>{};
  final calls = <String>[];
  final directChatsMap = <String, List<String>>{};
  final accountDataWrites = <({String type, Map<String, Object?> content})>[];
  Map<String, Object?>? createdWith;

  @override
  String? get userID => '@me:server';

  @override
  Map<String, List<String>> get directChats => directChatsMap;

  @override
  Future<void> setAccountData(
    String userId,
    String type,
    Map<String, Object?> content,
  ) async {
    calls.add('setAccountData');
    accountDataWrites.add((type: type, content: Map.of(content)));
  }

  @override
  Future<CachedProfileInformation> getUserProfile(
    String userId, {
    Duration timeout = const Duration(seconds: 30),
    Duration maxCacheAge = const Duration(days: 1),
  }) async {
    calls.add('getUserProfile');
    final error = profileError;
    if (error != null) throw error;
    return CachedProfileInformation.fromProfile(
      ProfileInformation(),
      outdated: false,
      updated: DateTime.now(),
    );
  }

  @override
  String? getDirectChatFromUserId(String userId) => directRoomId;

  @override
  Room? getRoomById(String id) => knownRooms[id];

  @override
  Future<String> createRoom({
    List<Invite3pid>? invite3pid,
    List<String>? invite,
    bool? isDirect,
    CreateRoomPreset? preset,
    List<StateEvent>? initialState,
    String? name,
    String? topic,
    String? roomAliasName,
    Map<String, Object?>? powerLevelContentOverride,
    Visibility? visibility,
    String? roomVersion,
    Map<String, Object?>? creationContent,
  }) async {
    calls.add('createRoom');
    createdWith = {
      'invite': invite,
      'isDirect': isDirect,
      'preset': preset,
      'initialState': initialState,
    };
    final error = createError;
    if (error != null) throw error;
    if (registerCreatedRoom) {
      knownRooms['!new:server'] = _FakeRoom(id: '!new:server');
    }
    return '!new:server';
  }

  @override
  Future<SyncUpdate> waitForRoomInSync(
    String roomId, {
    bool join = false,
    bool invite = false,
    bool leave = false,
  }) async {
    calls.add('waitForRoomInSync');
    // Only the sync that follows createRoom fails; accepting an invite must not.
    final error = calls.contains('createRoom') ? syncError : null;
    if (error != null) throw error;
    return SyncUpdate(nextBatch: '');
  }

  @override
  Future<void> leaveRoom(String roomId, {String? reason}) async =>
      calls.add('leaveRoom');

  @override
  Future<void> forgetRoom(String roomId) async => calls.add('forgetRoom');
}

void main() {
  const contact = '@alice:server';
  late _FakeClient client;
  late DirectChatDatasourceImpl datasource;

  setUp(() {
    client = _FakeClient();
    datasource = DirectChatDatasourceImpl(client);
  });

  Future<String> create() => datasource.createDirectChat(contactMxId: contact);

  test('a forbidden profile stops the creation', () async {
    client.profileError = MatrixException.fromJson({
      'errcode': 'M_FORBIDDEN',
      'error': 'no',
    });

    await expectLater(
      create(),
      throwsA(isA<CreateDirectChatForbiddenException>()),
    );
    expect(client.calls, ['getUserProfile']);
  });

  test('another profile failure does not stop the creation', () async {
    client.profileError = MatrixException.fromJson({
      'errcode': 'M_NOT_FOUND',
      'error': 'no profile',
    });
    client.syncError = Exception('stop here');

    await expectLater(
      create(),
      throwsA(isA<CreateDirectChatFailedException>()),
    );
    expect(client.calls, contains('createRoom'));
  });

  test('leaves and forgets the room it created when it fails', () async {
    client.syncError = Exception('sync timeout');

    await expectLater(
      create(),
      throwsA(isA<CreateDirectChatFailedException>()),
    );
    expect(client.calls, [
      'getUserProfile',
      'createRoom',
      'waitForRoomInSync',
      'leaveRoom',
      'forgetRoom',
    ]);
  });

  test(
    'a profile lookup that is not a Matrix error is a typed failure',
    () async {
      client.profileError = const SocketException('Network is unreachable');

      await expectLater(
        create(),
        throwsA(isA<CreateDirectChatFailedException>()),
      );
      expect(client.calls, ['getUserProfile']);
    },
  );

  test('an Error after the room is created still cleans it up', () async {
    client.syncError = StateError('sdk bug');

    await expectLater(create(), throwsStateError);
    expect(client.calls, containsAllInOrder(['leaveRoom', 'forgetRoom']));
  });

  test('an Error before the room exists is not wrapped', () async {
    client.createError = StateError('sdk bug');

    await expectLater(create(), throwsStateError);
    expect(client.calls, isNot(contains('leaveRoom')));
  });

  test(
    'creates an invited, direct, private room and records it as a DM',
    () async {
      client.registerCreatedRoom = true;

      expect(await create(), '!new:server');

      expect(client.createdWith, {
        'invite': [contact],
        'isDirect': true,
        'preset': CreateRoomPreset.trustedPrivateChat,
        'initialState': null,
      });
      expect(client.accountDataWrites, hasLength(1));
      expect(client.accountDataWrites.single.type, 'm.direct');
      expect(client.accountDataWrites.single.content, {
        contact: ['!new:server'],
      });
      expect(client.calls, isNot(contains('leaveRoom')));
    },
  );

  group('with an existing direct chat', () {
    const existingId = '!dm:server';

    void givenExisting(_FakeRoom room) {
      client.directRoomId = existingId;
      client.knownRooms[existingId] = room;
    }

    // The new room is not registered in the fake client, so the creation stops
    // after createRoom; reaching it proves the existing chat was not reused.
    Future<void> expectCreatesANewRoom() async {
      client.syncError = Exception('stop after createRoom');
      await expectLater(
        create(),
        throwsA(isA<CreateDirectChatFailedException>()),
      );
      expect(client.calls, contains('createRoom'));
    }

    test('a joined chat is returned without creating a room', () async {
      givenExisting(_FakeRoom(id: existingId));

      expect(await create(), existingId);
      expect(client.calls, ['getUserProfile']);
    });

    test('a pending invite is accepted', () async {
      final room = _FakeRoom(id: existingId, membership: Membership.invite);
      givenExisting(room);

      expect(await create(), existingId);
      expect(room.joinCalled, isTrue);
      expect(client.calls, isNot(contains('createRoom')));
    });

    test('an invite that does not become joined creates a new room', () async {
      givenExisting(
        _FakeRoom(
          id: existingId,
          membership: Membership.invite,
          joinedAfterJoin: false,
        ),
      );

      await expectCreatesANewRoom();
    });

    test('an abandoned chat creates a new room', () async {
      givenExisting(_FakeRoom(id: existingId, abandoned: true));

      await expectCreatesANewRoom();
    });

    test('a mapping to another person creates a new room', () async {
      givenExisting(_FakeRoom(id: existingId, peer: '@bob:server'));

      await expectCreatesANewRoom();
    });

    test('a left chat creates a new room', () async {
      givenExisting(_FakeRoom(id: existingId, membership: Membership.leave));

      await expectCreatesANewRoom();
    });
  });

  group('isUsableDirectChat', () {
    test('is false for an unknown room', () {
      expect(
        datasource.isUsableDirectChat(
          roomId: '!x:server',
          contactMxId: contact,
        ),
        isFalse,
      );
    });

    test('is true for a DM with the contact and false for another', () {
      client.knownRooms['!dm:server'] = _FakeRoom(id: '!dm:server');

      expect(
        datasource.isUsableDirectChat(
          roomId: '!dm:server',
          contactMxId: contact,
        ),
        isTrue,
      );
      expect(
        datasource.isUsableDirectChat(
          roomId: '!dm:server',
          contactMxId: '@bob:server',
        ),
        isFalse,
      );
    });
  });

  test('without an active client it is a programmer error', () {
    expect(
      () => const DirectChatDatasourceImpl(
        null,
      ).createDirectChat(contactMxId: contact),
      throwsStateError,
    );
  });
}
