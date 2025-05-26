import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/reactions/reactions_repository.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:matrix/matrix.dart';

class GetRecentReactionsInteractor {
  final ReactionsRepository _repository = getIt.get<ReactionsRepository>();

  Future<Category?> execute() async {
    try {
      final reactions = await _repository.getRecentReactions();
      return Category(
        id: EmojiPickerConfiguration.recentCategoryId,
        emojiIds: reactions,
      );
    } catch (exception) {
      Logs().e('GetRecentReactionsInteractor', exception);
      return null;
    }
  }
}
