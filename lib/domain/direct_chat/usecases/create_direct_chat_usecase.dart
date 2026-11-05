import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';

class CreateDirectChatUseCase {
  const CreateDirectChatUseCase(this._repository);

  final DirectChatRepository _repository;

  /// Returns the id of the direct chat with [contactMxId].
  ///
  /// Throws [CreateDirectChatRoomMismatchException] when the room is not a
  /// usable direct chat with the contact, and the exceptions of
  /// [DirectChatRepository.createDirectChat] otherwise.
  Future<String> execute({
    required String contactMxId,
    bool enableEncryption = false,
  }) async {
    final roomId = await _repository.createDirectChat(
      contactMxId: contactMxId,
      enableEncryption: enableEncryption,
    );
    if (!_repository.isUsableDirectChat(
      roomId: roomId,
      contactMxId: contactMxId,
    )) {
      throw CreateDirectChatRoomMismatchException(
        roomId: roomId,
        contactMxId: contactMxId,
      );
    }
    return roomId;
  }
}
