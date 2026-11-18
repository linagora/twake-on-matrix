import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.provider.dart';
import 'package:twake_chat/pages/search/search_state.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';

part 'search_controller.g.dart';

@riverpod
class SearchController extends _$SearchController {
  @override
  SearchState build() => const SearchState.idle();

  /// Ends in `ownProfile`, `room` or `draft`, which the screen navigates to;
  /// ignored while a lookup is running.
  Future<void> openContact({
    required String matrixId,
    String? displayName,
  }) async {
    if (state is SearchOpening) return;
    state = const SearchState.opening();
    if (matrixId == ref.read(activeUserIdProvider)) {
      state = const SearchState.ownProfile();
      return;
    }
    try {
      final roomId = await ref
          .read(findDirectChatUseCaseProvider)
          .execute(contactMxId: matrixId);
      if (!ref.mounted) return;
      state = roomId == null
          ? SearchState.draft(matrixId: matrixId, displayName: displayName)
          : SearchState.room(roomId);
    } finally {
      if (ref.mounted && state is SearchOpening) {
        state = const SearchState.idle();
      }
    }
  }
}
