import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_state.freezed.dart';

@freezed
sealed class SearchResultState with _$SearchResultState {
  const factory SearchResultState.idle() = SearchResultIdle;

  const factory SearchResultState.opening() = SearchResultOpening;

  const factory SearchResultState.ownProfile() = SearchResultOwnProfile;

  const factory SearchResultState.room(String roomId) = SearchResultRoom;

  const factory SearchResultState.draft({
    required String matrixId,
    String? displayName,
  }) = SearchResultDraft;
}
