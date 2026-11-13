import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';

class FindDirectChatUseCase {
  const FindDirectChatUseCase(this._repository);

  final DirectChatRepository _repository;

  /// Returns the id of the direct chat to open with [contactMxId], or null
  /// when a draft has to be started instead.
  Future<String?> execute({required String contactMxId}) async =>
      _repository.findDirectChat(contactMxId: contactMxId);
}
