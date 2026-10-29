import 'package:flutter_emoji_mart/flutter_emoji_mart.dart'
    show Category, EmojiPickerConfiguration;
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/reactions/exceptions/recent_reactions_exception.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.dart';

extension GetRecentReactionsCategory on GetRecentReactionsUseCase {
  Future<Category?> recentCategory() async {
    try {
      return Category(
        id: EmojiPickerConfiguration.recentCategoryId,
        emojiIds: await execute(),
      );
    } on GetRecentReactionsException catch (e, s) {
      Logs().e('GetRecentReactionsUseCase::recentCategory()', e, s);
      return null;
    }
  }
}

extension StoreRecentReactionsOrLog on StoreRecentReactionsUseCase {
  Future<void> executeOrLog({required String emojiId}) async {
    try {
      await execute(emojiId: emojiId);
    } on StoreRecentReactionsException catch (e, s) {
      Logs().e('StoreRecentReactionsUseCase::executeOrLog()', e, s);
    }
  }
}
