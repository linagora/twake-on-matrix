import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_failed.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_loading.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_success.dart';
import 'package:matrix/matrix.dart';

/// Manually implements direct chat creation instead of using client.startDirectChat()
/// to enable:
/// 1. Custom error recovery with automatic cleanup on failure
/// 2. Handling existing rooms with different membership states (invite/join/leave)
/// 3. Fine-grained control over encryption setup and room creation parameters
///
/// NOTE: This implementation should remain aligned with Matrix SDK's startDirectChat
/// behavior when possible to benefit from upstream fixes and improvements.
class CreateDirectChatInteractor {
  /// Creates or retrieves a direct chat room with the specified contact.
  ///
  /// Returns early if an existing room is found, otherwise creates a new room.
  /// Handles three existing room cases:
  /// 1. Already joined -> return existing room immediately
  /// 2. Invited -> accept invite, wait for sync, return room
  /// 3. Left/No room -> continue to create new room below
  Stream<Either<Failure, Success>> execute({
    required String contactMxId,
    required Client client,
    List<StateEvent>? initialState,
    bool enableEncryption = true,
    bool waitForSync = true,
    Map<String, dynamic>? powerLevelContentOverride,
    CreateRoomPreset? preset = CreateRoomPreset.trustedPrivateChat,
  }) async* {
    yield const Right(CreateDirectChatLoading());

    try {
      await client.getUserProfile(contactMxId);
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_FORBIDDEN) {
        yield const Left(NoPermissionForCreateChat());
        return;
      } else {
        rethrow;
      }
    }
    String? roomId;
    try {
      // Check if a direct chat already exists with this contact
      final directChatRoomId = client.getDirectChatFromUserId(contactMxId);
      if (directChatRoomId != null) {
        final room = client.getRoomById(directChatRoomId);
        if (room != null && !room.isAbandonedDMRoom) {
          // Case 1: Already joined - return existing room
          if (room.membership == Membership.join) {
            yield Right(CreateDirectChatSuccess(roomId: directChatRoomId));
            return;
          } else if (room.membership == Membership.invite) {
            // Case 2: Pending invite - accept and wait for sync
            await room.join();
            // Wait for sync to update membership status before checking
            if (waitForSync) {
              await client.waitForRoomInSync(directChatRoomId, join: true);
            }
            // After sync, verify membership is not leave
            final updatedRoom = client.getRoomById(directChatRoomId);
            if (updatedRoom != null &&
                updatedRoom.membership == Membership.join) {
              yield Right(CreateDirectChatSuccess(roomId: directChatRoomId));
              return;
            }
          }
          // Case 3: Left room - continue to create new room below
        }
      }

      // Add encryption state if enabled
      if (enableEncryption) {
        initialState ??= [];
        if (!initialState.any((s) => s.type == EventTypes.Encryption)) {
          initialState.add(
            StateEvent(
              content: {
                'algorithm': Client.supportedGroupEncryptionAlgorithms.first,
              },
              type: EventTypes.Encryption,
            ),
          );
        }
      }
      // Create new direct chat room with the contact invited at creation
      // time. The invite must be part of the createRoom payload so the
      // server associates is_direct with an actual two-party room from the
      // start. A separate inviteUser call after creation can cause some
      // homeservers to treat the room as a group rather than a DM.
      roomId = await client.createRoom(
        invite: [contactMxId],
        isDirect: true,
        preset: preset,
        initialState: initialState,
        powerLevelContentOverride: powerLevelContentOverride,
      );

      // Wait for room to sync before proceeding
      if (waitForSync) {
        await client.waitForRoomInSync(roomId, join: true);
        // Verify room exists after sync
        final room = client.getRoomById(roomId);
        if (room == null) {
          throw Exception('Room not synced after waitForRoomInSync');
        }
      }

      // Mark as direct chat so both sides recognise it as a DM
      await Room(id: roomId, client: client).addToDirectChat(contactMxId);

      yield Right(CreateDirectChatSuccess(roomId: roomId));
    } catch (e, s) {
      Logs().e('CreateDirectChatInteractor', e, s);
      if (roomId != null) {
        try {
          await client.leaveRoom(roomId);
          await client.forgetRoom(roomId);
        } catch (e) {
          Logs().e('CreateDirectChatInteractor: Failed to clean up room', e);
        }
      }
      yield Left(CreateDirectChatFailed(exception: e));
    }
  }
}
