import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:matrix/matrix.dart';

class StoreRecentReactionsInteractor {
  final ReactionsRepository _repository = getIt.get<ReactionsRepository>();

  Future<void> execute({required String emojiId}) async {
    try {
      if (emojiId.isEmpty) {
        return;
      }
      final reactions = await _repository.getRecentReactions();
      final updatedReactions = List<String>.from(
        reactions,
      ).combineRecentReactions(emojiId: emojiId);
      await _repository.storeRecentReactions(updatedReactions);
    } catch (exception) {
      Logs().e('GetRecentReactionsInteractor', exception);
    }
  }
}
