import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';

class _FakeClient extends Fake implements Client {
  Object? profileError;
  Object? syncError;
  final calls = <String>[];

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
  String? getDirectChatFromUserId(String userId) => null;

  @override
  Room? getRoomById(String id) => null;

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
    final error = syncError;
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
  late DirectChatRepositoryImpl repository;

  setUp(() {
    client = _FakeClient();
    repository = DirectChatRepositoryImpl(client);
  });

  Future<String> create() => repository.createDirectChat(
    contactMxId: contact,
    enableEncryption: false,
  );

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

  test('without an active client it is a programmer error', () {
    expect(
      () => const DirectChatRepositoryImpl(
        null,
      ).createDirectChat(contactMxId: contact, enableEncryption: false),
      throwsStateError,
    );
  });
}
