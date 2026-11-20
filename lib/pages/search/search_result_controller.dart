import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.provider.dart';
import 'package:twake_chat/pages/search/search_result_state.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

part 'search_result_controller.g.dart';

@riverpod
class SearchResultController extends _$SearchResultController {
  @override
  SearchResultState build() => const SearchResultState.idle();

  /// Ends in `ownProfile`, `room` or `draft`, which the screen navigates to;
  /// ignored while a lookup is running.
  Future<void> openContact({
    required String matrixId,
    String? displayName,
  }) async {
    if (state is SearchResultOpening) return;
    state = const SearchResultState.opening();
    if (matrixId == ref.read(activeUserIdProvider)) {
      state = const SearchResultState.ownProfile();
      return;
    }
    try {
      final roomId = await ref
          .read(findDirectChatUseCaseProvider)
          .execute(contactMxId: matrixId);
      if (!ref.mounted) return;
      state = roomId == null
          ? SearchResultState.draft(
              matrixId: matrixId,
              displayName: displayName,
            )
          : SearchResultState.room(roomId);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      ref.read(reportFailureProvider)(
        error,
        stackTrace,
        'SearchResultController::openContact',
      );
    } finally {
      if (ref.mounted && state is SearchResultOpening) {
        state = const SearchResultState.idle();
      }
    }
  }
}
