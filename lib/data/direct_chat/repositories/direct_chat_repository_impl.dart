import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';

/// Creates the direct chat by hand instead of `client.startDirectChat()` to
/// recover from a failure by leaving the room, to handle an existing room in
/// each membership state, and to control the encryption and creation
/// parameters. Keep it aligned with the SDK's `startDirectChat` where possible.
class DirectChatRepositoryImpl implements DirectChatRepository {
  const DirectChatRepositoryImpl(this._client);

  final Client? _client;

  Client get _requireClient =>
      _client ?? (throw StateError('No active Matrix client'));

  @override
  Future<String> createDirectChat({
    required String contactMxId,
    required bool enableEncryption,
  }) async {
    final client = _requireClient;
    await _checkProfile(client, contactMxId);

    try {
      return await _joinExistingOrCreate(client, contactMxId, enableEncryption);
    } on Exception catch (e, s) {
      Logs().e('DirectChatRepositoryImpl::createDirectChat() failed', e, s);
      throw CreateDirectChatFailedException(e);
    }
  }

  Future<String> _joinExistingOrCreate(
    Client client,
    String contactMxId,
    bool enableEncryption,
  ) async {
    final existingRoomId = await _joinExistingDirectChat(client, contactMxId);
    if (existingRoomId != null) return existingRoomId;
    return _createNewDirectChat(client, contactMxId, enableEncryption);
  }

  /// Leaves the created room on any failure, so it does not leak. The error
  /// is rethrown as is: an Exception is wrapped by the caller, an Error (G4)
  /// is not.
  Future<String> _createNewDirectChat(
    Client client,
    String contactMxId,
    bool enableEncryption,
  ) async {
    String? roomId;
    try {
      // The invite is part of the createRoom payload so the server sees an
      // is_direct room with two parties from the start; a separate inviteUser
      // call can make some homeservers treat the room as a group.
      roomId = await client.createRoom(
        invite: [contactMxId],
        isDirect: true,
        preset: CreateRoomPreset.trustedPrivateChat,
        initialState: enableEncryption ? [_encryptionState()] : null,
      );
      await _awaitRoomInSync(client, roomId);
      // Both sides must recognise the room as a DM.
      await Room(id: roomId, client: client).addToDirectChat(contactMxId);
      return roomId;
    } catch (_) {
      if (roomId != null) await _cleanUp(client, roomId);
      rethrow;
    }
  }

  Future<void> _awaitRoomInSync(Client client, String roomId) async {
    await client.waitForRoomInSync(roomId, join: true);
    if (client.getRoomById(roomId) == null) {
      throw Exception('Room not synced after waitForRoomInSync');
    }
  }

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) {
    final room = _requireClient.getRoomById(roomId);
    if (room == null) return false;
    if (room.isUsableDirectChatWith(contactMxId)) return true;
    Logs().w(
      'DirectChatRepositoryImpl: refusing non-matching room '
      'intended=$contactMxId room=${room.id} '
      'isDirect=${room.isDirectChat} '
      'peer=${room.directChatMatrixID} '
      'joined=${room.summary.mJoinedMemberCount}',
    );
    return false;
  }

  /// A forbidden profile stops the creation. Any other Matrix error is logged
  /// and the creation goes on, as the contact may have no profile yet. A
  /// failure that is not a Matrix error (offline, timeout) is a typed failure.
  /// Profile lookup: https://spec.matrix.org/v1.11/client-server-api/#get_matrixclientv3profileuserid
  /// (403 `M_FORBIDDEN` when the server refuses to share the profile).
  Future<void> _checkProfile(Client client, String contactMxId) async {
    try {
      await client.getUserProfile(contactMxId);
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        throw const CreateDirectChatForbiddenException();
      }
      Logs().w('DirectChatRepositoryImpl: profile lookup failed', e);
    } on Exception catch (e, s) {
      Logs().e('DirectChatRepositoryImpl: profile lookup failed', e, s);
      throw CreateDirectChatFailedException(e);
    }
  }

  /// Returns the id of a usable joined direct chat, accepting a pending
  /// invite; null when a new room has to be created (no mapping, left room,
  /// abandoned room or a room that is not a DM with the contact).
  Future<String?> _joinExistingDirectChat(
    Client client,
    String contactMxId,
  ) async {
    final roomId = client.getDirectChatFromUserId(contactMxId);
    if (roomId == null) return null;
    final room = client.getRoomById(roomId);
    if (room == null || room.isAbandonedDMRoom) return null;
    if (!room.isUsableDirectChatWith(contactMxId)) {
      Logs().w(
        'DirectChatRepositoryImpl: ignoring invalid direct mapping '
        'contactMxId=$contactMxId roomId=$roomId '
        'isDirectChat=${room.isDirectChat} '
        'peer=${room.directChatMatrixID} '
        'joined=${room.summary.mJoinedMemberCount}',
      );
      return null;
    }
    if (room.membership == Membership.join) return roomId;
    if (room.membership != Membership.invite) return null;

    await room.join();
    await client.waitForRoomInSync(roomId, join: true);
    final joined = client.getRoomById(roomId);
    final usable =
        joined != null &&
        joined.membership == Membership.join &&
        joined.isUsableDirectChatWith(contactMxId);
    return usable ? roomId : null;
  }

  StateEvent _encryptionState() => StateEvent(
    content: {'algorithm': Client.supportedGroupEncryptionAlgorithms.first},
    type: EventTypes.Encryption,
  );

  Future<void> _cleanUp(Client client, String roomId) async {
    try {
      await client.leaveRoom(roomId);
      await client.forgetRoom(roomId);
    } on Exception catch (e) {
      Logs().e('DirectChatRepositoryImpl: failed to clean up room', e);
    }
  }
}
