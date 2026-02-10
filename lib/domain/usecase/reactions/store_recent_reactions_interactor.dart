import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/reactions/reactions_repository.dart';
import 'package:fluffychat/utils/string_extension.dart';
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
