import 'package:twake_chat/domain/reactions/exceptions/recent_reactions_exception.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

class StoreRecentReactionsUseCase {
  const StoreRecentReactionsUseCase(this._repository);

  static const maxRecentReactions = 12;

  final ReactionsRepository _repository;

  Future<void> execute({required String emojiId}) async {
    if (emojiId.isEmpty) return;
    try {
      final reactions = await _repository.getRecentReactions();
      await _repository.storeRecentReactions(
        combine(reactions, emojiId: emojiId),
      );
    } catch (e, s) {
      Error.throwWithStackTrace(StoreRecentReactionsException(e), s);
    }
  }

  static List<String> combine(
    List<String> reactions, {
    required String emojiId,
  }) => [
    emojiId,
    ...reactions.where((id) => id != emojiId),
  ].take(maxRecentReactions).toList();
}
